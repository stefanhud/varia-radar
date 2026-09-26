import SwiftUI

/// Bar under the status line: start the ride on the Watch, then pause or end it.
/// Big buttons, so they're easy to hit on the bike, even with gloves.
struct RideControlBar: View {
    @ObservedObject var link: WatchWorkoutLink

    var body: some View {
        HStack(spacing: 12) {
            switch link.phase {
            case .idle, .finished, .failed:
                Button {
                    link.startRideOnWatch()
                } label: {
                    Label("Start ride", systemImage: "applewatch")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(Palette.threatNone, in: Capsule())
                        .foregroundColor(.black)
                }
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundColor(isFailure ? Palette.threatApproaching : Palette.label)
                    .lineLimit(3)
                Spacer(minLength: 0)
            case .starting, .saving:
                ProgressView().tint(Palette.label)
                Text(link.phase == .starting ? "Starting on your Watch…" : "Saving to Fitness…")
                    .font(.system(size: 13))
                    .foregroundColor(Palette.label)
                Spacer()
            case .running, .paused:
                Circle()
                    .fill(link.phase == .paused ? Palette.threatApproaching : Palette.threatFast)
                    .frame(width: 10, height: 10)
                Text(link.phase == .paused ? "PAUSED" : "RECORDING")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Button {
                    link.togglePause()
                } label: {
                    Image(systemName: link.phase == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 60, height: 48)
                        .background(Color(white: 0.18), in: Capsule())
                        .foregroundColor(.white)
                }
                HoldToEndButton { link.end() }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
    }

    private var isFailure: Bool {
        if case .failed = link.phase { return true }
        return false
    }

    private var statusText: String {
        switch link.phase {
        case .failed(let message):
            return message
        case .finished:
            guard let summary = link.summary else { return "Ride ended" }
            let km = String(format: "%.1f", summary.distanceMeters / 1000)
            var text = "Saved to Fitness · \(km) km · \(RideFormat.duration(summary.duration))"
            if let effort = summary.effort { text += " · effort \(effort)" }
            return text
        default:
            return "Starts a cycling workout on your Watch"
        }
    }
}

/// Ending needs a one-second press, so a bump in the road can't stop the ride.
struct HoldToEndButton: View {
    let action: () -> Void
    @State private var pressing = false

    var body: some View {
        Text("Hold to end")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .frame(height: 48)
            .background(alignment: .leading) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.threatFast.opacity(0.3))
                        Capsule()
                            .fill(Palette.threatFast)
                            .frame(width: pressing ? geo.size.width : 0)
                    }
                }
            }
            .clipShape(Capsule())
            .animation(pressing ? .linear(duration: 1) : .easeOut(duration: 0.2), value: pressing)
            .onLongPressGesture(minimumDuration: 1, maximumDistance: 30) {
                action()
            } onPressingChanged: { isPressing in
                pressing = isPressing
            }
    }
}
