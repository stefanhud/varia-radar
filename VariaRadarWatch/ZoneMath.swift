import HealthKit

/// Turns heart rate into a zone number (Z1–Z5) using the zones from your Health
/// settings, so they match what the Workout app shows.
enum ZoneMath {
    private static let bpm = HKUnit.count().unitDivided(by: .minute())

    static func zone(forHeartRate heartRate: Double, in configuration: HKWorkoutZoneConfiguration?) -> Int? {
        guard let zones = configuration?.zones, !zones.isEmpty else { return nil }
        var number = 1
        for (position, zone) in sorted(zones).enumerated() where heartRate >= lowerBound(of: zone) {
            number = position + 1
        }
        return number
    }

    /// 1-based position of a zone within its configuration, for display as Z1–Z5.
    static func position(of zone: HKWorkoutZone, in configuration: HKWorkoutZoneConfiguration) -> Int {
        (sorted(configuration.zones).firstIndex { $0.index == zone.index } ?? 0) + 1
    }

    private static func sorted(_ zones: [HKWorkoutZone]) -> [HKWorkoutZone] {
        zones.sorted { lowerBound(of: $0) < lowerBound(of: $1) }
    }

    private static func lowerBound(of zone: HKWorkoutZone) -> Double {
        zone.minimum?.doubleValue(for: bpm) ?? 0
    }
}
