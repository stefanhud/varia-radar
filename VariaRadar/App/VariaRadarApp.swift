import SwiftUI

@main
struct VariaRadarApp: App {
    init() {
        AppSettings.registerDefaults()
        // Pick up rides started on the Watch, even when this app launches in the background.
        WatchWorkoutLink.shared.activate()
        #if DEBUG
        if CommandLine.arguments.contains("-demo") { WatchWorkoutLink.shared.startDemoRide() }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RadarScreen()
                .preferredColorScheme(.dark)
        }
    }
}
