import SwiftUI
import HealthKit
import WatchKit

/// Lets the iPhone launch this app straight into a workout, and picks a workout
/// back up if the app crashes mid-ride.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WorkoutManager.shared.start(configuration: workoutConfiguration)
    }

    func handleActiveWorkoutRecovery() {
        WorkoutManager.shared.recover()
    }
}

@main
struct VariaRideApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @StateObject private var workout = WorkoutManager.shared

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-demo") {
            WorkoutManager.shared.startDemo(showingAlert: arguments.contains("-demoAlert"))
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(workout)
        }
    }
}
