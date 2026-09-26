import Foundation
import QuartzCore

/// Simulated cars approaching from behind, so the simulator (which has no
/// Bluetooth) still has a live radar to show while we design the screen.
final class MockRadarProvider: RadarProvider {
    var onVehicles: (([Vehicle]) -> Void)?
    var onConnection: ((ConnectionState) -> Void)?
    var onBattery: ((Int?) -> Void)?

    private var timer: Timer?
    private var lastTick = CACurrentMediaTime()

    private struct SimCar {
        let id: Int
        var distance: Double     // meters behind you
        var closingKmh: Double   // how much faster than you it is moving
    }
    private var cars: [SimCar] = []
    private var nextId = 1
    private var spawnAccumulator = 0.0
    private var spawnTarget = Double.random(in: 3...6)

    /// Screenshot mode: the cars hold still in a picture-perfect scene
    /// (green far back, amber coming up, red close behind).
    private let frozen: Bool

    init(frozen: Bool = false) {
        self.frozen = frozen
    }

    func start() {
        onConnection?(.connected)
        onBattery?(78)
        lastTick = CACurrentMediaTime()

        // Seed the same scene as the design mockup: far/slow, mid, and fast.
        cars = frozen
            ? [SimCar(id: newId(), distance: 118, closingKmh: 15),
               SimCar(id: newId(), distance: 72, closingKmh: 30),
               SimCar(id: newId(), distance: 40, closingKmh: 46)]
            : [SimCar(id: newId(), distance: 125, closingKmh: 18),
               SimCar(id: newId(), distance: 70, closingKmh: 31),
               SimCar(id: newId(), distance: 34, closingKmh: 52)]

        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onBattery?(nil)
        onConnection?(.disconnected)
    }

    private func newId() -> Int {
        defer { nextId += 1 }
        return nextId
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = now - lastTick
        lastTick = now

        if !frozen {
            for i in cars.indices {
                cars[i].distance -= (cars[i].closingKmh / 3.6) * dt
            }
            cars.removeAll { $0.distance <= 0 }

            spawnAccumulator += dt
            if spawnAccumulator >= spawnTarget {
                spawnAccumulator = 0
                spawnTarget = Double.random(in: 3...6)
                if cars.count < 4 {
                    cars.append(SimCar(id: newId(),
                                       distance: Double.random(in: 110...140),
                                       closingKmh: Double.random(in: 12...55)))
                }
            }
        }

        let vehicles = cars.map {
            Vehicle(id: $0.id,
                    distanceMeters: $0.distance,
                    closingSpeedKmh: $0.closingKmh,
                    threat: ThreatModel.level(distanceMeters: $0.distance, closingKmh: $0.closingKmh))
        }
        onVehicles?(vehicles)
    }
}
