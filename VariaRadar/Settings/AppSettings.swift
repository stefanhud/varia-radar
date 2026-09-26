import Foundation

/// Everything the Settings screen controls, stored in UserDefaults. Views bind to these
/// with `@AppStorage(AppSettings.Key.…)`; other code reads the static properties.
enum AppSettings {
    enum Key {
        static let rideWithWatch = "rideWithWatch"
        static let showHeartRate = "showHeartRate"
        static let showCadence = "showCadence"
        static let alertTiming = "alertTiming"
        static let alertSound = "alertSound"
        static let edgeGlow = "edgeGlow"
        static let autoDim = "autoDim"
    }

    /// Call once at launch so every setting has its default until you change it.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Key.rideWithWatch: true,
            Key.showHeartRate: true,
            Key.showCadence: true,
            Key.alertTiming: AlertTiming.normal.rawValue,
            Key.alertSound: true,
            Key.edgeGlow: true,
            Key.autoDim: false,
        ])
    }

    static var rideWithWatch: Bool { UserDefaults.standard.bool(forKey: Key.rideWithWatch) }
    static var showHeartRate: Bool { rideWithWatch && UserDefaults.standard.bool(forKey: Key.showHeartRate) }
    static var showCadence: Bool { rideWithWatch && UserDefaults.standard.bool(forKey: Key.showCadence) }
    static var alertSound: Bool { UserDefaults.standard.bool(forKey: Key.alertSound) }
    static var autoDim: Bool { UserDefaults.standard.bool(forKey: Key.autoDim) }
    static var alertTiming: AlertTiming {
        AlertTiming(rawValue: UserDefaults.standard.string(forKey: Key.alertTiming) ?? "") ?? .normal
    }
}

/// How early cars turn amber and red, in seconds before they'd reach you.
enum AlertTiming: String, CaseIterable, Identifiable {
    case early, normal, late

    var id: String { rawValue }

    var title: String {
        switch self {
        case .early:  return "Early"
        case .normal: return "Normal"
        case .late:   return "Late"
        }
    }

    var amberBelowSeconds: Double {
        switch self {
        case .early:  return 16
        case .normal: return 12
        case .late:   return 8
        }
    }

    var redBelowSeconds: Double {
        switch self {
        case .early:  return 7
        case .normal: return 5
        case .late:   return 3.5
        }
    }
}
