import SwiftUI

/// The hero: a vertical lane where each detected vehicle is a dot placed by how
/// far behind you it is. Cars appear near the top (far away) and slide down
/// toward the "YOU" marker as they close in. Color = threat, number = closing speed.
struct RadarStripView: View {
    let vehicles: [Vehicle]

    private let maxRange: Double = 140          // meters the Varia can see
    private let distanceTicks: [Double] = [140, 100, 60, 20]

    /// The radar reports whole metres about ten times a second; gliding between
    /// updates for this long makes the dots move smoothly instead of ticking.
    private let glide = Animation.linear(duration: 0.12)

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let laneX = w * 0.42

            ZStack(alignment: .topLeading) {
                // Distance gridlines + labels
                ForEach(distanceTicks, id: \.self) { d in
                    let y = yFor(d, height: h)
                    Path { p in
                        p.move(to: CGPoint(x: 44, y: y))
                        p.addLine(to: CGPoint(x: w - 8, y: y))
                    }
                    .stroke(Palette.gridLine, lineWidth: 1)

                    Text("\(Int(d))m")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.label)
                        .position(x: 22, y: y)
                }

                // "YOU" marker pinned at the bottom
                VStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Palette.youMarker)
                    Text("YOU")
                        .font(.system(size: 10))
                        .foregroundColor(Palette.label)
                }
                .position(x: laneX, y: h - 22)

                // One dot per vehicle, plus its closing speed
                ForEach(vehicles) { vehicle in
                    let y = yFor(vehicle.distanceMeters, height: h)

                    VehicleDot(threat: vehicle.threat)
                        .position(x: laneX, y: y)
                        .animation(glide, value: y)

                    let speed = Text("\(Int(vehicle.closingSpeedKmh))")
                        .font(.system(size: speedFontSize(vehicle.threat), weight: .semibold))
                        .foregroundColor(Palette.color(for: vehicle.threat))
                    let unit = Text(" km/h")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.label)
                    Text("\(speed)\(unit)")
                        .contentTransition(.identity)   // numbers swap instantly; only the position glides
                        .fixedSize()
                        .position(x: laneX + 52, y: y)
                        .animation(glide, value: y)
                }
            }
        }
    }

    /// Map a distance (0...maxRange) to a y position. Far = near the top,
    /// close = near the bottom, leaving room for the YOU marker.
    private func yFor(_ distance: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(distance, 0), maxRange)
        let usable = height - 40
        return CGFloat(1 - clamped / maxRange) * usable + 8
    }

    private func speedFontSize(_ threat: ThreatLevel) -> CGFloat {
        switch threat {
        case .fast:        return 26
        case .approaching: return 22
        case .none:        return 20
        }
    }
}

/// A single colored dot. Fast-approaching vehicles get a pulsing ring.
struct VehicleDot: View {
    let threat: ThreatLevel

    var body: some View {
        ZStack {
            if threat == .fast {
                PulseRing()
            }
            Circle()
                .fill(Palette.color(for: threat))
                .frame(width: size, height: size)
        }
    }

    private var size: CGFloat {
        switch threat {
        case .fast:        return 26
        case .approaching: return 20
        case .none:        return 16
        }
    }
}

/// The expanding ring behind a fast-approaching vehicle. It's a separate view so the
/// animation starts fresh whenever a car turns red — real cars usually appear far
/// away (green) and only turn red as they close in.
struct PulseRing: View {
    @State private var expanded = false

    var body: some View {
        Circle()
            .stroke(Palette.threatFast.opacity(0.6), lineWidth: 2)
            .frame(width: 26, height: 26)
            .scaleEffect(expanded ? 2.3 : 1)
            .opacity(expanded ? 0 : 0.6)
            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: expanded)
            .onAppear { expanded = true }
    }
}
