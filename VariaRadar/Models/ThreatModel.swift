import Foundation

/// Decides how dangerous a vehicle is from how many seconds it would take to reach
/// you at its current closing speed. A fast car far back can be more urgent than a
/// slow car close by — distance alone misses that. The amber and red cut-offs come
/// from the "Alert timing" setting.
enum ThreatModel {
    static let closeBehindMeters: Double = 15   // right on your wheel, even if not closing

    /// Seconds until the vehicle reaches you, or nil if it isn't really closing in.
    static func timeToReach(distanceMeters d: Double, closingKmh s: Double) -> Double? {
        let metersPerSecond = s / 3.6
        guard metersPerSecond > 0.5 else { return nil }
        return d / metersPerSecond
    }

    static func level(distanceMeters d: Double, closingKmh s: Double) -> ThreatLevel {
        let timing = AppSettings.alertTiming
        if let t = timeToReach(distanceMeters: d, closingKmh: s) {
            if t < timing.redBelowSeconds { return .fast }
            if t < timing.amberBelowSeconds { return .approaching }
        }
        if d < closeBehindMeters { return .approaching }
        return .none
    }
}
