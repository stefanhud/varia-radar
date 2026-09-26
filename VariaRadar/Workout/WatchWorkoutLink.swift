import Foundation
import HealthKit

/// The iPhone side of the Watch workout. It starts the ride on the Watch, picks up
/// the mirrored workout with its live numbers, and sends car alerts to the wrist.
final class WatchWorkoutLink: NSObject, ObservableObject {
    static let shared = WatchWorkoutLink()

    enum Phase: Equatable {
        case idle, starting, running, paused, saving, finished
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var snapshot: WorkoutSnapshot?
    @Published private(set) var summary: WorkoutSummary?

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var snapshotReceivedAt = Date()
    private var rideStartedAt: Date?
    private var savedRideCheck: Timer?

    var isRiding: Bool { phase == .running || phase == .paused }

    private static let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
    private static let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.cyclingCadence),
    ]

    /// Call once at launch, so a ride started on the Watch is mirrored here even
    /// if this app wasn't open.
    func activate() {
        healthStore.workoutSessionMirroringStartHandler = { [weak self] mirrored in
            DispatchQueue.main.async { self?.attach(mirrored) }
        }
    }

    func startRideOnWatch() {
        guard !isRiding, phase != .starting, phase != .saving else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        phase = .starting
        snapshot = nil
        summary = nil
        rideStartedAt = Date()
        stopSavedRideCheck()

        Task {
            do {
                try await healthStore.requestAuthorization(toShare: Self.typesToShare, read: Self.typesToRead)
                try await healthStore.startWatchApp(toHandle: configuration)
                // The Watch now starts the workout and mirrors it back — see attach(_:).
            } catch {
                await MainActor.run { self.phase = .failed("Couldn't reach your Apple Watch.") }
            }
        }

        // If the Watch never mirrors back, don't spin forever.
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, self.phase == .starting else { return }
            self.phase = .failed("No answer from the Watch. Open Varia Ride on it once to allow access, then try again.")
        }
    }

    func togglePause() {
        send(.command(phase == .paused ? .resume : .pause))
    }

    func end() {
        send(.command(.end))
    }

    func sendCarAlert(distanceMeters: Double, closingKmh: Double) {
        guard phase == .running else { return }
        send(.carAlert(CarAlert(distanceMeters: Int(distanceMeters.rounded()),
                                closingKmh: Int(closingKmh.rounded()))))
    }

    #if DEBUG
    /// Screenshot mode (launch argument `-demo`): acts as if a Watch ride were running.
    func startDemoRide() {
        phase = .running
        rideStartedAt = Date().addingTimeInterval(-2_745)
        snapshot = WorkoutSnapshot(isPaused: false, heartRate: 148, zone: 3, cadence: 88,
                                   distanceMeters: 18_400, activeEnergyKcal: 512, elapsed: 2_745)
        snapshotReceivedAt = Date()
    }
    #endif

    /// Ride time right now, counting on smoothly between the Watch's updates.
    func elapsed(at date: Date = Date()) -> TimeInterval? {
        guard isRiding, let snapshot else { return nil }
        guard phase == .running else { return snapshot.elapsed }
        return snapshot.elapsed + max(0, date.timeIntervalSince(snapshotReceivedAt))
    }

    private func send(_ message: RideMessage) {
        guard let session, let data = message.encoded() else { return }
        session.sendToRemoteWorkoutSession(data: data) { _, _ in }
    }

    private func attach(_ mirrored: HKWorkoutSession) {
        session = mirrored
        mirrored.delegate = self
        snapshot = nil
        summary = nil
        rideStartedAt = mirrored.startDate ?? rideStartedAt ?? Date()
        stopSavedRideCheck()
        // Take the ride's real state: iOS can hand over a ride that's already stopping
        // or over, e.g. when it relaunches the app just as the ride ends.
        switch mirrored.state {
        case .paused:
            phase = .paused
        case .stopped:
            phase = .saving
        case .ended:
            rideIsOver()
        default:
            phase = .running
        }
    }

    /// The Watch has finished the ride. If its summary never arrived (the phone was
    /// asleep at the time), the saved ride is looked up in Health instead.
    private func rideIsOver() {
        session = nil
        phase = .finished
        if summary == nil { keepLookingForSavedRide() }
    }

    private func receive(_ message: RideMessage) {
        switch message {
        case .snapshot(let snapshot):
            self.snapshot = snapshot
            snapshotReceivedAt = Date()
            if isRiding { phase = snapshot.isPaused ? .paused : .running }
        case .finished(let summary):
            self.summary = summary
            phase = .finished
            stopSavedRideCheck()
        case .carAlert, .command:
            break
        }
    }

    // MARK: Finding the saved ride

    /// Health syncs from the Watch with a delay, so keep looking for a while.
    private func keepLookingForSavedRide() {
        lookForSavedRide()
        savedRideCheck?.invalidate()
        let giveUpAt = Date().addingTimeInterval(600)
        savedRideCheck = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] timer in
            guard let self, self.summary == nil, Date() < giveUpAt else {
                timer.invalidate()
                return
            }
            self.lookForSavedRide()
        }
    }

    private func stopSavedRideCheck() {
        savedRideCheck?.invalidate()
        savedRideCheck = nil
    }

    /// If the Watch saved this ride to Health, show it as saved with its totals.
    private func lookForSavedRide() {
        guard let start = rideStartedAt else { return }
        let newestFirst = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                  predicate: HKQuery.predicateForSamples(withStart: start.addingTimeInterval(-120), end: nil),
                                  limit: 1,
                                  sortDescriptors: newestFirst) { [weak self] _, samples, _ in
            guard let workout = samples?.first as? HKWorkout,
                  workout.sourceRevision.source.bundleIdentifier.hasPrefix("com.stefanhud.VariaRadar") else { return }
            let summary = WorkoutSummary(savedRide: workout)
            DispatchQueue.main.async {
                guard let self, self.summary == nil, !self.isRiding, self.phase != .starting else { return }
                self.summary = summary
                self.phase = .finished
                self.stopSavedRideCheck()
            }
        }
        healthStore.execute(query)
    }
}

extension WatchWorkoutLink: HKWorkoutSessionDelegate {
    // Every callback first checks it's about the current ride, so a late event
    // from an earlier ride can't change what the screen shows.

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            guard workoutSession === self.session else { return }
            switch toState {
            case .running:
                self.phase = .running
            case .paused:
                self.phase = .paused
            case .stopped:
                self.phase = .saving
            case .ended:
                // Keep the last snapshot: the band shows the final ride until the next one.
                self.rideIsOver()
            default:
                break
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            guard workoutSession === self.session else { return }
            self.phase = .failed(error.localizedDescription)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        let messages = data.compactMap(RideMessage.decode)
        DispatchQueue.main.async {
            guard workoutSession === self.session else { return }
            messages.forEach(self.receive)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: Error?) {
        DispatchQueue.main.async {
            guard workoutSession === self.session, self.isRiding else { return }
            switch workoutSession.state {
            case .stopped, .ended:
                // The Watch ended the ride; only its goodbye got lost on the way.
                self.rideIsOver()
            default:
                self.session = nil
                self.phase = .failed("Lost contact with the Watch. If the ride is still running there, tap Start ride to reconnect.")
                self.keepLookingForSavedRide()
            }
        }
    }
}

private extension WorkoutSummary {
    /// Totals read back from the ride the Watch saved to Health.
    init(savedRide workout: HKWorkout) {
        let bpm = HKUnit.count().unitDivided(by: .minute())
        func total(_ identifier: HKQuantityTypeIdentifier, _ unit: HKUnit) -> Double {
            workout.statistics(for: HKQuantityType(identifier))?.sumQuantity()?.doubleValue(for: unit) ?? 0
        }
        self.init(duration: workout.duration,
                  distanceMeters: total(.distanceCycling, .meter()),
                  activeEnergyKcal: total(.activeEnergyBurned, .kilocalorie()),
                  averageHeartRate: workout.statistics(for: HKQuantityType(.heartRate))?
                      .averageQuantity().map { Int($0.doubleValue(for: bpm).rounded()) },
                  elevationGainMeters: (workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?
                      .doubleValue(for: .meter()) ?? 0,
                  effort: nil)
    }
}
