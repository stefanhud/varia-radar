import SwiftUI

@main
struct VariaRadarApp: App {
    init() {
        AppSettings.registerDefaults()
        // Pick up rides started on the Watch, even when this app launches in the background.
        WatchWorkoutLink.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            RadarScreen()
                .preferredColorScheme(.dark)
        }
    }
}
