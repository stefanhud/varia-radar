import SwiftUI

/// Colors for the whole app. The screen is intentionally pure black with
/// vivid threat colors for maximum contrast when glancing down at the bike.
enum Palette {
    static let background = Color.black
    static let gridLine = Color(white: 0.11)
    static let label = Color(white: 0.55)
    static let value = Color.white
    static let youMarker = Color(red: 0.35, green: 0.61, blue: 0.91)

    // Threat colors
    static let threatNone = Color(red: 0.19, green: 0.82, blue: 0.35)        // green
    static let threatApproaching = Color(red: 1.00, green: 0.62, blue: 0.04) // amber
    static let threatFast = Color(red: 1.00, green: 0.23, blue: 0.19)        // red

    static func color(for threat: ThreatLevel) -> Color {
        switch threat {
        case .none: return threatNone
        case .approaching: return threatApproaching
        case .fast: return threatFast
        }
    }
}
