import ActivityKit
import SwiftUI
import WidgetKit

/// The ride's Live Activity: the Dynamic Island while you're in another app, and a
/// banner on the Lock Screen. Tapping either one opens Varia Radar.
struct RideLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideActivityAttributes.self) { context in
            LockScreenRideView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                // With heart rate: HR on the left, speed on the right.
                // Radar only: speed on the left, the nearest car on the right.
                DynamicIslandExpandedRegion(.leading) {
                    if state.heartRate != nil {
                        HeartRateBlock(state: state)
                    } else {
                        StatBlock(value: state.speedKmh.map(String.init) ?? "—", unit: "km/h", alignment: .leading)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if state.heartRate != nil {
                        StatBlock(value: state.speedKmh.map(String.init) ?? "—", unit: "km/h")
                    } else {
                        NearestCarBlock(state: state)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        MiniRadarStrip(cars: state.cars, connected: state.radarConnected)
                        if state.hasRideTotals {
                            HStack {
                                Text(state.distanceKm.map { String(format: "%.1f km", $0) } ?? "— km")
                                Spacer()
                                RideClock(state: state)
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                        }
                    }
                    .padding(.horizontal, 10)   // keep clear of the island's rounded corners
                }
            } compactLeading: {
                RadarGlyph(state: state)
            } compactTrailing: {
                CompactReadout(state: state)
            } minimal: {
                RadarGlyph(state: state)
            }
            .keylineTint(state.highestThreat.map(Palette.color(for:)) ?? Palette.threatNone)
        }
    }
}

/// Car icon in the colour of the most urgent car, or a radar icon when the road
/// behind is clear (green when connected, grey when not).
struct RadarGlyph: View {
    let state: RideActivityAttributes.ContentState

    var body: some View {
        if let threat = state.highestThreat {
            Image(systemName: "car.rear.fill")
                .foregroundStyle(Palette.color(for: threat))
        } else {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundStyle(state.radarConnected ? Palette.threatNone : Palette.label)
        }
    }
}

/// The nearest car's distance when there is one, otherwise heart rate (or speed).
struct CompactReadout: View {
    let state: RideActivityAttributes.ContentState

    var body: some View {
        if let car = state.cars.first {
            Text("\(car.distanceMeters) m")
                .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.color(for: car.threat))
        } else if let heartRate = state.heartRate {
            HStack(spacing: 3) {
                Image(systemName: "heart.fill").foregroundStyle(.red)
                Text("\(heartRate)").monospacedDigit()
            }
            .font(.system(.body, design: .rounded).weight(.semibold))
        } else if let speed = state.speedKmh {
            Text("\(speed) km/h")
                .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
        } else {
            Text("—").foregroundStyle(Palette.label)
        }
    }
}

struct HeartRateBlock: View {
    let state: RideActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
                Text(state.heartRate.map(String.init) ?? "—")
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
            }
            if let zone = state.zone {
                Text("Z\(zone)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .background(ZoneColor.color(for: zone), in: Capsule())
            }
        }
    }
}

struct StatBlock: View {
    let value: String
    let unit: String
    var alignment: HorizontalAlignment = .trailing

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
            Text(unit)
                .font(.system(size: 12))
                .foregroundStyle(Palette.label)
        }
    }
}

/// The closest car in its threat colour, or "Clear" when the road behind is empty.
struct NearestCarBlock: View {
    let state: RideActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let car = state.cars.first {
                Text("\(car.distanceMeters) m")
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Palette.color(for: car.threat))
                Text("+\(car.closingKmh) km/h")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.label)
            } else {
                Text("Clear")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(state.radarConnected ? Palette.threatNone : Palette.label)
                Text(state.radarConnected ? "no cars" : "radar off")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.label)
            }
        }
    }
}

/// The ride time: counts up by itself while riding, fixed when paused or done.
struct RideClock: View {
    let state: RideActivityAttributes.ContentState

    var body: some View {
        if let start = state.rideTimerStart {
            Text(start, style: .timer)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90, alignment: .trailing)
        } else if let elapsed = state.rideElapsed {
            Text(RideFormat.duration(elapsed))
        } else {
            Text("—").foregroundStyle(Palette.label)
        }
    }
}

/// A sideways version of the app's radar: cars come in from the left and move
/// right toward you and your bike.
struct MiniRadarStrip: View {
    let cars: [RideActivityAttributes.Car]
    let connected: Bool
    private let range = 140.0

    var body: some View {
        GeometryReader { geo in
            let lane = geo.size.width - 26
            let midY = geo.size.height / 2
            Capsule()
                .fill(Color(white: 0.18))
                .frame(width: lane, height: 6)
                .position(x: lane / 2, y: midY)
            ForEach(Array(cars.enumerated()), id: \.offset) { _, car in
                let size: CGFloat = car.threat == .fast ? 14 : 11
                Circle()
                    .fill(Palette.color(for: car.threat))
                    .frame(width: size, height: size)
                    .position(x: lane * (1 - min(Double(car.distanceMeters), range) / range), y: midY)
            }
            Image(systemName: "bicycle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.youMarker)
                .position(x: geo.size.width - 11, y: midY)
        }
        .frame(height: 18)
        .opacity(connected ? 1 : 0.4)
    }
}

struct LockScreenRideView: View {
    let state: RideActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                if state.heartRate != nil {
                    HeartRateBlock(state: state)
                    Spacer()
                }
                StatBlock(value: state.speedKmh.map(String.init) ?? "—", unit: "km/h",
                          alignment: state.heartRate == nil ? .leading : .trailing)
                Spacer()
                if state.hasRideTotals {
                    StatBlock(value: state.distanceKm.map { String(format: "%.1f", $0) } ?? "—", unit: "km")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        RideClock(state: state)
                            .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                        Text("time")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.label)
                    }
                } else {
                    NearestCarBlock(state: state)
                }
            }
            MiniRadarStrip(cars: state.cars, connected: state.radarConnected && !isStale)
            if isStale {
                Text("Open Varia Radar to reconnect")
                    .font(.caption)
                    .foregroundStyle(Palette.label)
            }
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}
