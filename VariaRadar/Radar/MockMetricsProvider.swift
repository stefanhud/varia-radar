import Foundation
import QuartzCore

/// Fake heart rate, speed and distance so the metrics band looks alive in the
/// simulator. On a real device these come from the Apple Watch and GPS instead.
final class MockMetricsProvider: MetricsProvider {
    var onUpdate: ((MetricsSample) -> Void)?

    private var timer: Timer?
    private var lastTick = CACurrentMediaTime()
    private var startTime = CACurrentMediaTime()
    private var speed = 30.0
    private var distanceKm = 0.0

    func start() {
        startTime = CACurrentMediaTime()
        lastTick = startTime
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = now - lastTick
        lastTick = now

        speed += Double.random(in: -0.5...0.5)
        speed = min(max(speed, 22), 38)
        distanceKm += (speed / 3.6) * dt / 1000.0
        let hr = 145 + Int((6 * sin((now - startTime) / 8)).rounded())
        let cadence = 88 + Int((4 * sin((now - startTime) / 5)).rounded())

        onUpdate?(MetricsSample(heartRate: hr,
                                hrZone: Self.zone(for: hr),
                                cadence: cadence,
                                speedKmh: speed,
                                distanceKm: distanceKm))
    }

    /// Simple 5-zone split for the simulator; real rides use your zones from Health.
    static func zone(for hr: Int) -> Int {
        switch hr {
        case ..<114: return 1
        case ..<133: return 2
        case ..<152: return 3
        case ..<171: return 4
        default:     return 5
        }
    }
}
