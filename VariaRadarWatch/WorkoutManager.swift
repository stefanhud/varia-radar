import Foundation
import HealthKit
import CoreLocation
import CoreMotion
import WatchKit

/// Runs the cycling workout on the Watch. It records heart rate, calories,
/// distance, cadence (from a sensor paired to the Watch), the GPS route and the
/// climb into HealthKit, so the ride appears in Fitness like any other workout,
/// and mirrors live numbers to the iPhone.
final class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()

    enum Phase: Equatable {
        case idle, starting, running, paused, saving, finished
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var heartRate: Int?
    @Published private(set) var zone: Int?
    @Published private(set) var cadence: Int?
    @Published private(set) var distanceMeters = 0.0
    @Published private(set) var activeEnergyKcal = 0.0
    @Published private(set) var elevationGainMeters = 0.0
    @Published private(set) var carAlert: CarAlert?
    @Published private(set) var summary: WorkoutSummary?

    let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter()
    private var lastAltitude: Double?
    private var zoneConfiguration: HKWorkoutZoneConfiguration?
    private var hasLiveZone = false
    private var lastSentToPhone = Date.distantPast

    private static let bpm = HKUnit.count().unitDivided(by: .minute())

    private static let recordedTypes: [HKQuantityTypeIdentifier] = [
        .heartRate, .activeEnergyBurned, .distanceCycling, .cyclingCadence, .cyclingSpeed, .cyclingPower,
    ]

    private static var typesToShare: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType(), HKSeriesType.workoutRoute(),
                                        HKQuantityType(.workoutEffortScore)]
        recordedTypes.forEach { types.insert(HKQuantityType($0)) }
        return types
    }

    private static var typesToRead: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType(), HKSeriesType.workoutRoute(),
                                        HKQuantityType(.workoutEffortScore)]
        recordedTypes.forEach { types.insert(HKQuantityType($0)) }
        return types
    }

    // MARK: Controls

    /// Ask for Health and location access up front, so a ride started from the
    /// iPhone doesn't stall on a permission prompt.
    func requestPermissions() {
        healthStore.requestAuthorization(toShare: Self.typesToShare, read: Self.typesToRead) { _, _ in }
        locationManager.requestWhenInUseAuthorization()
    }

    func startFromWatch() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        start(configuration: configuration)
    }

    func start(configuration: HKWorkoutConfiguration) {
        DispatchQueue.main.async { self.beginWorkout(configuration) }
    }

    func togglePause() {
        if phase == .paused { session?.resume() } else { session?.pause() }
    }

    func end() {
        session?.stopActivity(with: .now)
    }

    /// Back to the start screen after looking at the summary.
    func reset() {
        phase = .idle
        summary = nil
        heartRate = nil
        zone = nil
        cadence = nil
        distanceMeters = 0
        activeEnergyKcal = 0
        elevationGainMeters = 0
        hasLiveZone = false
    }

    func elapsed(at date: Date) -> TimeInterval {
        builder?.elapsedTime(at: date) ?? 0
    }

    // MARK: Workout lifecycle

    private func beginWorkout(_ configuration: HKWorkoutConfiguration) {
        // Already riding: the iPhone probably lost the mirror, so reconnect it.
        if let session, phase == .running || phase == .paused {
            session.startMirroringToCompanionDevice { _, _ in }
            return
        }
        guard phase != .starting, phase != .saving else { return }
        reset()
        phase = .starting

        Task {
            do {
                try await healthStore.requestAuthorization(toShare: Self.typesToShare, read: Self.typesToRead)
                let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                let builder = session.associatedWorkoutBuilder()
                builder.dataSource = makeDataSource(for: configuration)
                session.delegate = self
                builder.delegate = self
                let zones = try? await healthStore.preferredWorkoutZoneConfiguration(for: HKQuantityType(.heartRate))

                await MainActor.run {
                    self.session = session
                    self.builder = builder
                    // Saved together with the workout, which is what puts the map in Fitness.
                    self.routeBuilder = builder.seriesBuilder(for: HKSeriesType.workoutRoute()) as? HKWorkoutRouteBuilder
                    self.zoneConfiguration = zones
                }

                let start = Date()
                session.startActivity(with: start)
                try await builder.beginCollection(at: start)
                try? await session.startMirroringToCompanionDevice()
                await MainActor.run { self.startLocationAndAltitude() }
            } catch {
                await MainActor.run {
                    self.phase = .failed("Couldn't start: \(error.localizedDescription)")
                    self.session = nil
                    self.builder = nil
                }
            }
        }
    }

    private func makeDataSource(for configuration: HKWorkoutConfiguration) -> HKLiveWorkoutDataSource {
        let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        // Sensors paired to the Watch (like a cadence sensor) only feed a workout
        // when their data types are asked for explicitly.
        for identifier in [HKQuantityTypeIdentifier.cyclingCadence, .cyclingSpeed, .cyclingPower] {
            dataSource.enableCollection(for: HKQuantityType(identifier), predicate: nil)
        }
        return dataSource
    }

    /// Relaunched after a crash mid-ride: pick the workout back up.
    func recover() {
        healthStore.recoverActiveWorkoutSession { [weak self] session, _ in
            guard let self, let session else { return }
            DispatchQueue.main.async {
                let builder = session.associatedWorkoutBuilder()
                builder.dataSource = self.makeDataSource(for: session.workoutConfiguration)
                session.delegate = self
                builder.delegate = self
                self.session = session
                self.builder = builder
                self.routeBuilder = builder.seriesBuilder(for: HKSeriesType.workoutRoute()) as? HKWorkoutRouteBuilder
                self.phase = session.state == .paused ? .paused : .running
                self.startLocationAndAltitude()
                session.startMirroringToCompanionDevice { _, _ in }
            }
        }
    }

    private func finish(at endDate: Date) {
        guard phase != .saving, phase != .finished, let session, let builder else { return }
        phase = .saving
        locationManager.stopUpdatingLocation()
        altimeter.stopRelativeAltitudeUpdates()
        let climb = elevationGainMeters
        let zones = zoneConfiguration

        Task {
            do {
                if climb > 0 {
                    try await builder.addMetadata([
                        HKMetadataKeyElevationAscended: HKQuantity(unit: .meter(), doubleValue: climb),
                    ])
                }
                try await builder.endCollection(at: endDate)
                let averageHeartRate = builder.statistics(for: HKQuantityType(.heartRate))?
                    .averageQuantity()?.doubleValue(for: Self.bpm)
                let duration = builder.elapsedTime(at: endDate)
                let distance = Self.total(of: .distanceCycling, in: builder, unit: .meter())
                let energy = Self.total(of: .activeEnergyBurned, in: builder, unit: .kilocalorie())
                let workout = try await builder.finishWorkout()

                // Apple only estimates effort for rides recorded by its own Workout app,
                // so add ours. It can still be changed in Fitness.
                var effort: Int?
                if let workout,
                   let estimate = EffortEstimate.score(for: workout, averageHeartRate: averageHeartRate, zones: zones),
                   await self.saveEffort(estimate, for: workout) {
                    effort = estimate
                }
                let summary = WorkoutSummary(duration: duration,
                                             distanceMeters: distance,
                                             activeEnergyKcal: energy,
                                             averageHeartRate: averageHeartRate.map { Int($0.rounded()) },
                                             elevationGainMeters: climb,
                                             effort: effort)

                // Tell the iPhone before the session, and its mirror, closes.
                if let data = RideMessage.finished(summary).encoded() {
                    try? await session.sendToRemoteWorkoutSession(data: data)
                }
                session.end()
                await MainActor.run {
                    self.summary = summary
                    self.phase = .finished
                    self.session = nil
                    self.builder = nil
                    self.routeBuilder = nil
                }
            } catch {
                session.end()
                await MainActor.run {
                    self.phase = .failed("Couldn't save the ride: \(error.localizedDescription)")
                    self.session = nil
                    self.builder = nil
                    self.routeBuilder = nil
                }
            }
        }
    }

    private static func total(of identifier: HKQuantityTypeIdentifier, in builder: HKLiveWorkoutBuilder, unit: HKUnit) -> Double {
        builder.statistics(for: HKQuantityType(identifier))?.sumQuantity()?.doubleValue(for: unit) ?? 0
    }

    /// Attaches an effort score to the saved workout, so Fitness shows it instead of
    /// asking. Returns false if it couldn't be saved (e.g. Health access for effort is off).
    private func saveEffort(_ score: Int, for workout: HKWorkout) async -> Bool {
        let sample = HKQuantitySample(type: HKQuantityType(.workoutEffortScore),
                                      quantity: HKQuantity(unit: .appleEffortScore(), doubleValue: Double(score)),
                                      start: workout.startDate,
                                      end: workout.endDate)
        return (try? await healthStore.relateWorkoutEffortSample(sample, with: workout, activity: nil)) ?? false
    }

    // MARK: Route and climb

    private func startLocationAndAltitude() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()

        lastAltitude = nil
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data, self.phase == .running else { return }
                self.trackClimb(data.relativeAltitude.doubleValue)
            }
        }
    }

    /// Adds up climbing, ignoring wobbles under a metre so sensor noise doesn't count.
    private func trackClimb(_ altitude: Double) {
        guard let last = lastAltitude else {
            lastAltitude = altitude
            return
        }
        let delta = altitude - last
        if delta >= 1 {
            elevationGainMeters += delta
            lastAltitude = altitude
        } else if delta <= -1 {
            lastAltitude = altitude
        }
    }

    // MARK: iPhone link

    private func sendSnapshotToPhone(force: Bool = false) {
        guard let session, force || Date().timeIntervalSince(lastSentToPhone) >= 1 else { return }
        lastSentToPhone = Date()
        let snapshot = WorkoutSnapshot(isPaused: phase == .paused,
                                       heartRate: heartRate,
                                       zone: zone,
                                       cadence: cadence,
                                       distanceMeters: distanceMeters,
                                       activeEnergyKcal: activeEnergyKcal,
                                       elapsed: elapsed(at: Date()))
        guard let data = RideMessage.snapshot(snapshot).encoded() else { return }
        session.sendToRemoteWorkoutSession(data: data) { _, _ in }
    }

    private func handle(_ message: RideMessage) {
        switch message {
        case .carAlert(let alert):
            carAlert = alert
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                if self?.carAlert == alert { self?.carAlert = nil }
            }
        case .command(.pause):
            session?.pause()
        case .command(.resume):
            session?.resume()
        case .command(.end):
            end()
        case .snapshot, .finished:
            break
        }
    }

    private func apply(_ statistics: HKStatistics) {
        switch statistics.quantityType {
        case HKQuantityType(.heartRate):
            guard let value = statistics.mostRecentQuantity()?.doubleValue(for: Self.bpm) else { return }
            heartRate = Int(value.rounded())
            if !hasLiveZone {
                zone = ZoneMath.zone(forHeartRate: value, in: zoneConfiguration)
            }
        case HKQuantityType(.activeEnergyBurned):
            activeEnergyKcal = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? activeEnergyKcal
        case HKQuantityType(.distanceCycling):
            distanceMeters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? distanceMeters
        case HKQuantityType(.cyclingCadence):
            if let rpm = statistics.mostRecentQuantity()?.doubleValue(for: Self.bpm) {
                cadence = Int(rpm.rounded())
            }
        default:
            break
        }
    }
}

// MARK: - HealthKit delegates

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.phase = .running
            case .paused:
                self.phase = .paused
            case .stopped, .ended:
                self.finish(at: date)
            default:
                break
            }
            self.sendSnapshotToPhone(force: true)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async { self.phase = .failed(error.localizedDescription) }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        let messages = data.compactMap(RideMessage.decode)
        DispatchQueue.main.async { messages.forEach(self.handle) }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didDisconnectFromRemoteDeviceWithError error: Error?) {
        // The ride keeps recording here; tapping Start ride on the iPhone reconnects.
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let statistics = collectedTypes.compactMap { ($0 as? HKQuantityType).flatMap(workoutBuilder.statistics(for:)) }
        DispatchQueue.main.async {
            statistics.forEach(self.apply)
            self.sendSnapshotToPhone()
        }
    }

    /// New in watchOS 27: Apple tells us when you move between heart-rate zones.
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didUpdateWorkoutZone zoneUpdate: HKLiveWorkoutZoneUpdate) {
        guard let group = zoneUpdate.zoneGroup,
              group.configuration.quantityType == HKQuantityType(.heartRate),
              let current = zoneUpdate.currentZoneDuration?.zone else { return }
        let number = ZoneMath.position(of: current, in: group.configuration)
        DispatchQueue.main.async {
            self.hasLiveZone = true
            self.zone = number
            self.sendSnapshotToPhone(force: true)
        }
    }
}

extension WorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Only keep reasonably precise fixes, and only while riding (not paused).
        let precise = locations.filter { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 50 }
        guard phase == .running, !precise.isEmpty, let routeBuilder else { return }
        routeBuilder.insertRouteData(precise) { _, _ in }
    }
}
