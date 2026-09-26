import SwiftUI

/// The slim band under the radar: heart rate (+ zone), cadence, speed, distance,
/// time. Big values, small labels, high contrast — made to read at a glance. A
/// metric with no sensor connected shows a dash rather than a fake number, and the
/// Settings switches can hide the ones you don't use.
struct DataBandView: View {
    let metrics: RideMetrics
    var showHeartRate = true
    var showCadence = true
    /// Distance and time come from the Watch ride, so they're hidden without one.
    var showRideTotals = true

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if showHeartRate {
                MetricCell(label: "HR",
                           value: metrics.heartRate.map { "\($0)" } ?? "—",
                           unit: nil,
                           zone: metrics.hrZone)
            }
            if showCadence {
                MetricCell(label: "CAD",
                           value: metrics.cadence.map { "\($0)" } ?? "—",
                           unit: metrics.cadence == nil ? nil : "rpm",
                           zone: nil)
            }
            MetricCell(label: "SPEED",
                       value: metrics.speedKmh.map { String(format: "%.0f", $0) } ?? "—",
                       unit: metrics.speedKmh == nil ? nil : "km/h",
                       zone: nil)
            if showRideTotals {
                MetricCell(label: "DIST",
                           value: metrics.distanceKm.map { String(format: "%.1f", $0) } ?? "—",
                           unit: metrics.distanceKm == nil ? nil : "km",
                           zone: nil)
                MetricCell(label: "TIME",
                           value: RideFormat.duration(metrics.elapsed),
                           unit: nil,
                           zone: nil)
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Palette.background)
        .overlay(alignment: .top) {
            Rectangle().frame(height: 1).foregroundColor(Palette.gridLine)
        }
    }
}

private struct MetricCell: View {
    let label: String
    let value: String
    let unit: String?
    let zone: Int?

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .tracking(0.5)
                .foregroundColor(Palette.label)
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Palette.value)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let zone {
                Text("Z\(zone)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 1)
                    .background(ZoneColor.color(for: zone))
                    .clipShape(Capsule())
            } else if let unit {
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(Palette.label)
            } else {
                Text(" ").font(.system(size: 10))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
