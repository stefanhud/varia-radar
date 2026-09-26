import SwiftUI
import Combine
import UIKit

/// Pulls together the radar targets and the ride metrics and publishes them to the
/// views. It doesn't know or care whether the data is simulated or from real
/// hardware — that's decided by which providers it gets.
final class RideViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var metrics: RideMetrics = .empty
    @Published var connection: ConnectionState = .disconnected
    @Published var radarBattery: Int?

    let workout: WatchWorkoutLink
    private let radar: RadarProvider
    private let metricsProvider: MetricsProvider?

    private var latest = MetricsSample()
    private var clock: Timer?
    private var alertedVehicleIds = Set<Int>()
    private var cancellables = Set<AnyCancellable>()
    private let liveActivity = RideLiveActivityController()
    private let dimmer = ScreenDimmer()
    private let alertSound = AlertSoundPlayer()

    /// Set while Settings is open, so the screen doesn't dim under you.
    var dimmingPaused = false

    /// True while a car is closing in fast; drives the red edge glow.
    var hasFastCar: Bool { vehicles.contains { $0.threat == .fast } }

    private var isOnScreen: Bool { UIApplication.shared.applicationState == .active }

    init(radar: RadarProvider, metrics: MetricsProvider?, workout: WatchWorkoutLink = .shared) {
        self.radar = radar
        self.metricsProvider = metrics
        self.workout = workout

        radar.onVehicles = { [weak self] vehicles in
            self?.update(vehicles)
        }
        radar.onConnection = { [weak self] state in
            self?.connection = state
        }
        radar.onBattery = { [weak self] percent in
            self?.radarBattery = percent
        }
        metrics?.onUpdate = { [weak self] sample in
            self?.latest = sample
            self?.rebuildMetrics()
        }
        // Rebuild whenever the Watch link changes; receive(on:) lets the new value land first.
        workout.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMetrics() }
            .store(in: &cancellables)
    }

    /// Chooses real hardware on device, simulated data in the simulator.
    convenience init() {
        #if targetEnvironment(simulator)
        let screenshotMode = CommandLine.arguments.contains("-demo")
        self.init(radar: MockRadarProvider(frozen: screenshotMode), metrics: MockMetricsProvider())
        #else
        self.init(radar: VariaBluetoothProvider(), metrics: LocationMetricsProvider())
        #endif
    }

    func start() {
        radar.start()
        metricsProvider?.start()

        // Ticks the ride time along smoothly between the Watch's updates.
        clock?.invalidate()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.rebuildMetrics() }
        RunLoop.main.add(t, forMode: .common)
        clock = t
        rebuildMetrics()
    }

    func stop() {
        radar.stop()
        metricsProvider?.stop()
        clock?.invalidate()
        clock = nil
    }

    private func update(_ vehicles: [Vehicle]) {
        self.vehicles = vehicles.sorted { $0.distanceMeters < $1.distanceMeters }

        // Alert once for each car that turns red: a tap on the wrist, plus a beep if
        // the app is on screen, or the Dynamic Island expanding if you're elsewhere.
        var islandAlert: CarAlert?
        if let newlyRed = vehicles.first(where: { $0.threat == .fast && !alertedVehicleIds.contains($0.id) }) {
            alertedVehicleIds.insert(newlyRed.id)
            workout.sendCarAlert(distanceMeters: newlyRed.distanceMeters, closingKmh: newlyRed.closingSpeedKmh)
            if isOnScreen {
                if AppSettings.alertSound { alertSound.play() }
            } else {
                islandAlert = CarAlert(distanceMeters: Int(newlyRed.distanceMeters.rounded()),
                                       closingKmh: Int(newlyRed.closingSpeedKmh.rounded()))
            }
        }
        alertedVehicleIds.formIntersection(vehicles.map(\.id))
        refreshLiveActivity(alert: islandAlert)
        updateDimming()
    }

    /// What the band shows depends on where the ride is:
    /// • riding: live numbers from the Watch (what gets saved to Fitness), plus speed
    ///   from the phone's GPS, which reacts fastest
    /// • ride over: the final distance and time stay put until the next ride starts
    /// • no ride yet: just the phone's speed (the simulator fakes the rest)
    private func rebuildMetrics() {
        let speed = latest.speedKmh
        switch workout.phase {
        case .running, .paused:
            let live = workout.snapshot
            metrics = RideMetrics(heartRate: live?.heartRate,
                                  hrZone: live?.zone,
                                  cadence: live?.cadence,
                                  speedKmh: speed,
                                  distanceKm: live.map { $0.distanceMeters / 1000 },
                                  elapsed: workout.elapsed() ?? 0)
        case .saving, .finished, .failed:
            if let distance = workout.summary?.distanceMeters ?? workout.snapshot?.distanceMeters,
               let time = workout.summary?.duration ?? workout.snapshot?.elapsed {
                metrics = RideMetrics(heartRate: nil, hrZone: nil, cadence: nil,
                                      speedKmh: speed, distanceKm: distance / 1000, elapsed: time)
            } else {
                metrics = beforeRide(speed: speed)
            }
        case .idle, .starting:
            metrics = beforeRide(speed: speed)
        }
        refreshLiveActivity(alert: nil)
        updateDimming()
    }

    private func beforeRide(speed: Double?) -> RideMetrics {
        RideMetrics(heartRate: latest.heartRate, hrZone: latest.hrZone, cadence: latest.cadence,
                    speedKmh: speed, distanceKm: latest.distanceKm, elapsed: 0)
    }

    // MARK: Screen dimming

    func screenTouched() {
        dimmer.touched()
    }

    /// iOS restores your brightness itself once the app goes to the background, so the
    /// dimmer can forget its state. (Not on a Control Center swipe: the app is only
    /// "inactive" then and the dimmed brightness stays.)
    func appMovedToBackground() {
        dimmer.reset()
    }

    /// Only dims while the radar is connected; otherwise nothing could wake it up.
    private func updateDimming() {
        let enabled = AppSettings.autoDim && connection == .connected && !dimmingPaused
        dimmer.update(enabled: enabled, carApproaching: vehicles.contains { $0.threat != .none })
    }

    // MARK: Live Activity

    /// Keeps the Dynamic Island going while the radar is connected or a ride is on.
    private func refreshLiveActivity(alert: CarAlert?) {
        let sessionActive = connection == .connected || workout.isRiding || workout.phase == .starting
        liveActivity.refresh(activityState(), sessionActive: sessionActive, alert: alert, sound: AppSettings.alertSound)
    }

    private func activityState() -> RideActivityAttributes.ContentState {
        var timerStart: Date?
        var fixedTime: TimeInterval?
        switch workout.phase {
        case .running:
            // Whole seconds, so the start doesn't wobble between updates.
            if let elapsed = workout.elapsed() {
                timerStart = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 - elapsed).rounded())
            }
        case .paused, .saving, .finished:
            fixedTime = metrics.elapsed
        default:
            break
        }
        return RideActivityAttributes.ContentState(
            cars: vehicles.prefix(4).map {
                RideActivityAttributes.Car(distanceMeters: Int($0.distanceMeters.rounded()),
                                           closingKmh: Int($0.closingSpeedKmh.rounded()),
                                           threat: $0.threat)
            },
            radarConnected: connection == .connected,
            heartRate: AppSettings.showHeartRate ? metrics.heartRate : nil,
            zone: AppSettings.showHeartRate ? metrics.hrZone : nil,
            speedKmh: metrics.speedKmh.map { Int($0.rounded()) },
            distanceKm: metrics.distanceKm.map { ($0 * 10).rounded() / 10 },
            rideTimerStart: timerStart,
            rideElapsed: fixedTime)
    }
}
