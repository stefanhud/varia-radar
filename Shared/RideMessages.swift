import Foundation

/// Messages passed between the iPhone and the Watch over the mirrored workout.
enum RideMessage: Codable, Equatable {
    case snapshot(WorkoutSnapshot)   // Watch → iPhone, about once a second
    case finished(WorkoutSummary)    // Watch → iPhone, once the ride is saved
    case carAlert(CarAlert)          // iPhone → Watch, when a car turns red
    case command(RideCommand)        // iPhone → Watch

    func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(_ data: Data) -> RideMessage? {
        try? JSONDecoder().decode(RideMessage.self, from: data)
    }
}

/// Live numbers from the Watch workout.
struct WorkoutSnapshot: Codable, Equatable {
    var isPaused: Bool
    var heartRate: Int?
    var zone: Int?
    var cadence: Int?
    var distanceMeters: Double
    var activeEnergyKcal: Double
    var elapsed: TimeInterval
}

/// Totals shown once a ride has been saved.
struct WorkoutSummary: Codable, Equatable {
    var duration: TimeInterval
    var distanceMeters: Double
    var activeEnergyKcal: Double
    var averageHeartRate: Int?
    var elevationGainMeters: Double
    var effort: Int?
}

/// A car closing in fast, shown on the Watch with a tap on the wrist.
struct CarAlert: Codable, Equatable {
    var distanceMeters: Int
    var closingKmh: Int
    var id = UUID()
}

enum RideCommand: String, Codable {
    case pause, resume, end
}
