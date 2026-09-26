import Foundation

/// The numbers shown in the slim band below the radar. Any field can be nil when
/// its source isn't available — heart rate, cadence and distance come from the
/// Watch ride, speed from the phone's GPS — so the band shows a dash instead.
struct RideMetrics: Equatable {
    var heartRate: Int?
    var hrZone: Int?
    var cadence: Int?
    var speedKmh: Double?
    var distanceKm: Double?
    var elapsed: TimeInterval

    static let empty = RideMetrics(heartRate: nil, hrZone: nil, cadence: nil, speedKmh: nil, distanceKm: nil, elapsed: 0)
}
