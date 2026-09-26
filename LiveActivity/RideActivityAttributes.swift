import ActivityKit
import Foundation

/// What the Dynamic Island and Lock Screen show while you ride. Shared by the app,
/// which starts and updates the Live Activity, and the widget extension, which draws it.
struct RideActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var cars: [Car]                  // nearest first, at most four
        var radarConnected: Bool
        var heartRate: Int?
        var zone: Int?
        var speedKmh: Int?
        var distanceKm: Double?
        var rideTimerStart: Date?        // while riding, the ride clock counts up from here by itself
        var rideElapsed: TimeInterval?   // paused or finished: a fixed time instead

        var highestThreat: ThreatLevel? {
            cars.map(\.threat).max { $0.rawValue < $1.rawValue }
        }

        /// Distance and time exist only during (or right after) a Watch ride.
        var hasRideTotals: Bool {
            distanceKm != nil || rideTimerStart != nil || rideElapsed != nil
        }
    }

    struct Car: Codable, Hashable {
        var distanceMeters: Int
        var closingKmh: Int
        var threat: ThreatLevel
    }
}
