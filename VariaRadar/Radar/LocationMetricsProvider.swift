import Foundation
import CoreLocation

/// Live speed from the phone's GPS. Distance, time, heart rate and cadence come
/// from the Watch ride instead, since that's what gets saved to Fitness.
final class LocationMetricsProvider: NSObject, MetricsProvider {
    var onUpdate: ((MetricsSample) -> Void)?

    private let manager = CLLocationManager()
    private var running = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        running = true
        manager.requestWhenInUseAuthorization()   // shows the permission prompt the first time
        manager.startUpdatingLocation()
    }

    func stop() {
        running = false
        manager.stopUpdatingLocation()
    }
}

extension LocationMetricsProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard running else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Skip stale or imprecise fixes, and fixes without a speed reading.
        guard let fix = locations.last(where: {
            $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 20
                && abs($0.timestamp.timeIntervalSinceNow) < 10
                && $0.speed >= 0
        }) else { return }
        onUpdate?(MetricsSample(speedKmh: fix.speed * 3.6))
    }
}
