import SwiftUI

/// Heart-rate zone colours, used on both the iPhone and the Watch.
enum ZoneColor {
    static func color(for zone: Int) -> Color {
        switch zone {
        case ...1: return Color(red: 0.35, green: 0.61, blue: 0.91)   // blue
        case 2:    return Color(red: 0.19, green: 0.82, blue: 0.35)   // green
        case 3:    return Color(red: 1.00, green: 0.84, blue: 0.04)   // yellow
        case 4:    return Color(red: 1.00, green: 0.58, blue: 0.00)   // orange
        default:   return Color(red: 1.00, green: 0.23, blue: 0.19)   // red
        }
    }
}
