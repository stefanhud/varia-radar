import Foundation

/// One reading of the ride numbers (except elapsed time, which the view model
/// tracks itself). Any field may be nil when that sensor isn't connected.
struct MetricsSample: Equatable {
    var heartRate: Int?
    var hrZone: Int?
    var cadence: Int?
    var speedKmh: Double?
    var distanceKm: Double?
}

/// Supplies the numbers the phone measures itself: `MockMetricsProvider` fakes them
/// all in the simulator, `LocationMetricsProvider` gives GPS speed on device. Heart
/// rate, cadence, distance and time come from the Watch ride.
protocol MetricsProvider: AnyObject {
    var onUpdate: ((MetricsSample) -> Void)? { get set }
    func start()
    func stop()
}
