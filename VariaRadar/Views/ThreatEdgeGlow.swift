import SwiftUI

/// Siri-style red glow that flows around the screen edges while a car is closing in
/// fast. It follows the phone's rounded screen corners and ignores touches.
struct ThreatEdgeGlow: View {
    private let colors: [Color] = [
        Color(red: 1.00, green: 0.18, blue: 0.18),   // red
        Color(red: 1.00, green: 0.45, blue: 0.20),   // orange-red
        Color(red: 0.90, green: 0.10, blue: 0.40),   // crimson
        Color(red: 1.00, green: 0.30, blue: 0.30),   // light red
        Color(red: 1.00, green: 0.18, blue: 0.18),   // back to the start, so the loop is seamless
    ]

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let flow = AngularGradient(colors: colors, center: .center,
                                       angle: .degrees((t * 120).truncatingRemainder(dividingBy: 360)))
            let pulse = 0.75 + 0.25 * sin(t * 5)
            let edge = ConcentricRectangle(corners: .concentric)
            ZStack {
                edge.stroke(flow, lineWidth: 36).blur(radius: 24).opacity(0.9 * pulse)   // wide soft glow
                edge.stroke(flow, lineWidth: 14).blur(radius: 6).opacity(pulse)          // brighter band
                edge.stroke(flow, lineWidth: 4)                                          // crisp edge
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
