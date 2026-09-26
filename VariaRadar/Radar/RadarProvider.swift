import Foundation

/// Connection status shown in the top bar.
enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connected
}

/// Supplies radar targets, connection status and the radar's battery level.
/// `MockRadarProvider` in the simulator, `VariaBluetoothProvider` (real Bluetooth)
/// on device. The screen doesn't care which one it's given.
protocol RadarProvider: AnyObject {
    var onVehicles: (([Vehicle]) -> Void)? { get set }
    var onConnection: ((ConnectionState) -> Void)? { get set }
    var onBattery: ((Int?) -> Void)? { get set }   // percent, nil when unknown
    func start()
    func stop()
}
