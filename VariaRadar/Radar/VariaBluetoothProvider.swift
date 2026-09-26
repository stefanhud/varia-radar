import Foundation
import CoreBluetooth

/// Connects to a Garmin Varia rear radar over Bluetooth Low Energy, turns its
/// notifications into `Vehicle` values, and reports the radar's battery level.
///
/// Protocol — reverse-engineered by the cycling community and confirmed against a
/// real RTL515 (a passing car tracked from 86 m down to 1 m):
///   • Radar service:  6A4E3200-667B-11E3-949A-0800200C9A66
///   • Measurement:    6A4E3203-667B-11E3-949A-0800200C9A66 (notify)
///   • Each notification is `1 + 3·N` bytes:
///       byte 0           — rolling sequence/header (ignored)
///       then, per target — [ target id , distance (m) , closing speed (km/h) ]
///   • A 1-byte notification means "no vehicles", so the screen clears.
///   • Other lengths (like the 2-byte `03 FE` sent after connecting) are a different
///     kind of message and are ignored.
///   • The service also has a read/write characteristic (…3205), probably settings; unused.
///   • Battery: the standard Bluetooth Battery service (180F), level in percent (2A19).
///
/// The threat colour is derived from distance + closing speed (see `ThreatModel`).
/// DEBUG builds print the radar's services and every packet, for troubleshooting.
final class VariaBluetoothProvider: NSObject, RadarProvider {
    var onVehicles: (([Vehicle]) -> Void)?
    var onConnection: ((ConnectionState) -> Void)?
    var onBattery: ((Int?) -> Void)?

    static let radarService = CBUUID(string: "6A4E3200-667B-11E3-949A-0800200C9A66")
    static let radarMeasurement = CBUUID(string: "6A4E3203-667B-11E3-949A-0800200C9A66")
    static let batteryService = CBUUID(string: "180F")
    static let batteryLevel = CBUUID(string: "2A19")

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var wantsToRun = false
    private var foundMeasurementChar = false
    private var connectedAt = Date()
    private var batteryCharacteristic: CBCharacteristic?
    private var batteryTimer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func start() {
        wantsToRun = true
        if central.state == .poweredOn { beginScan() }
    }

    func stop() {
        wantsToRun = false
        central.stopScan()
        if let peripheral { central.cancelPeripheralConnection(peripheral) }
        peripheral = nil
        forgetBattery()
        onConnection?(.disconnected)
    }

    private func beginScan() {
        guard wantsToRun, central.state == .poweredOn else { return }
        onConnection?(.scanning)
        central.scanForPeripherals(withServices: [Self.radarService], options: nil)
    }

    /// Reads the battery now and every few minutes after, in case the radar
    /// doesn't push updates by itself.
    private func watchBattery(_ characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        batteryCharacteristic = characteristic
        peripheral.readValue(for: characteristic)
        if characteristic.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
        batteryTimer?.invalidate()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self, let peripheral = self.peripheral, let characteristic = self.batteryCharacteristic else { return }
            peripheral.readValue(for: characteristic)
        }
    }

    private func forgetBattery() {
        batteryTimer?.invalidate()
        batteryTimer = nil
        batteryCharacteristic = nil
        onBattery?(nil)
    }

    /// Turn one radar notification into a list of vehicles.
    private func parse(_ data: Data) {
        let bytes = [UInt8](data)
        // Radar pages are 1 + 3·N bytes; anything else isn't car data, so don't let
        // it wipe the cars off the screen.
        guard (bytes.count - 1) % 3 == 0 else { return }
        guard bytes.count >= 4 else { onVehicles?([]); return }   // 1 byte = no vehicles

        let targetCount = (bytes.count - 1) / 3
        var vehicles: [Vehicle] = []
        var usedIds = Set<Int>()
        for i in 0..<targetCount {
            let base = 1 + i * 3
            let distance = Double(bytes[base + 1])
            let speed    = Double(bytes[base + 2])
            if distance == 0 && speed == 0 { continue }   // empty target slot

            // The first byte stays the same for a car's whole pass, so it identifies
            // it; the low 6 bits are used in case the top bits carry other flags.
            var id = Int(bytes[base] & 0x3F)
            if usedIds.contains(id) { id = 1000 + i }     // never hand SwiftUI duplicate IDs
            usedIds.insert(id)

            vehicles.append(
                Vehicle(id: id,
                        distanceMeters: distance,
                        closingSpeedKmh: speed,
                        threat: ThreatModel.level(distanceMeters: distance, closingKmh: speed))
            )
        }
        onVehicles?(vehicles.sorted { $0.distanceMeters < $1.distanceMeters })
    }
}

extension VariaBluetoothProvider: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if wantsToRun { beginScan() }
        default:
            onConnection?(.disconnected)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedAt = Date()
        onConnection?(.connected)
        peripheral.discoverServices(nil)   // all of them, so DEBUG logs show what the radar offers
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        beginScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        forgetBattery()
        onConnection?(.disconnected)
        if wantsToRun { beginScan() }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            #if DEBUG
            print("VARIA service \(service.uuid)")
            #endif
            switch service.uuid {
            case Self.radarService:
                peripheral.discoverCharacteristics(nil, for: service)
            case Self.batteryService:
                peripheral.discoverCharacteristics([Self.batteryLevel], for: service)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics = service.characteristics ?? []
        if service.uuid == Self.batteryService {
            if let level = characteristics.first(where: { $0.uuid == Self.batteryLevel }) {
                watchBattery(level, on: peripheral)
            }
            return
        }

        #if DEBUG
        for c in characteristics {
            print("VARIA characteristic \(c.uuid) properties=\(c.properties.rawValue)")
        }
        #endif

        if let measurement = characteristics.first(where: { $0.uuid == Self.radarMeasurement }) {
            foundMeasurementChar = true
            peripheral.setNotifyValue(true, for: measurement)
        } else {
            // Fallback: the expected radar characteristic wasn't found, so subscribe to
            // every notifiable one and let the logs reveal which carries the target data.
            for c in characteristics where c.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: c)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        if characteristic.uuid == Self.batteryLevel {
            if let percent = data.first { onBattery?(Int(percent)) }
            return
        }

        #if DEBUG
        let hex = [UInt8](data).map { String(format: "%02X", $0) }.joined(separator: " ")
        let seconds = String(format: "%.2f", Date().timeIntervalSince(connectedAt))
        let source = characteristic.uuid == Self.radarMeasurement ? "" : " \(characteristic.uuid)"
        print("VARIA +\(seconds)s\(source) [\(data.count)B]: \(hex)")
        #endif

        if foundMeasurementChar {
            // We know the radar characteristic — trust it for both targets and "all clear".
            if characteristic.uuid == Self.radarMeasurement { parse(data) }
        } else {
            // Fallback mode: assume any multi-byte packet is radar target data.
            if data.count >= 4 { parse(data) }
        }
    }
}
