import HealthKit

/// Estimates effort on Apple's 1–10 scale from the time spent in each heart-rate
/// zone, nudged up for long rides. Apple only estimates effort for rides recorded
/// by its own Workout app; without this, Fitness asks you to rate every ride.
enum EffortEstimate {
    private static let zoneScores: [Double] = [2, 4, 6, 8, 9.5]   // Z1 … Z5

    static func score(for workout: HKWorkout, averageHeartRate: Double?, zones: HKWorkoutZoneConfiguration?) -> Int? {
        let base: Double
        if let group = workout.zoneGroup(for: HKQuantityType(.heartRate)), let weighted = timeWeightedScore(group) {
            base = weighted
        } else if let averageHeartRate, let zone = ZoneMath.zone(forHeartRate: averageHeartRate, in: zones) {
            base = zoneScore(zone)
        } else {
            return nil
        }
        let hours = workout.endDate.timeIntervalSince(workout.startDate) / 3600
        let longRideBonus = min(2, max(0, hours - 1))   // +1 per hour past the first, up to +2
        return min(10, max(1, Int((base + longRideBonus).rounded())))
    }

    private static func timeWeightedScore(_ group: HKWorkoutZoneGroup) -> Double? {
        let total = group.zoneDurations.reduce(0) { $0 + $1.duration }
        guard total > 0 else { return nil }
        let weighted = group.zoneDurations.reduce(0) { sum, item in
            sum + zoneScore(ZoneMath.position(of: item.zone, in: group.configuration)) * item.duration
        }
        return weighted / total
    }

    private static func zoneScore(_ zone: Int) -> Double {
        zoneScores[min(max(zone, 1), zoneScores.count) - 1]
    }
}
