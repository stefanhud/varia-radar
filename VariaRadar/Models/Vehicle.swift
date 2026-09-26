import Foundation

/// How dangerous a detected vehicle is, worked out from its distance and closing
/// speed (see `ThreatModel`).
enum ThreatLevel: Int, Codable, Hashable {
    case none = 0        // detected, not really gaining on you
    case approaching = 1 // coming up behind you
    case fast = 2        // closing fast / very close
}

/// One vehicle the radar has detected behind you.
struct Vehicle: Identifiable, Equatable {
    let id: Int
    var distanceMeters: Double   // 0 = at your rear wheel, up to ~140 m detection range
    var closingSpeedKmh: Double  // how much faster the car is moving than you
    var threat: ThreatLevel
}
