import ActivityKit
import Foundation

/// Runs the ride's Live Activity (the Dynamic Island and the Lock Screen banner)
/// while the radar is connected or a Watch ride is in progress. Tapping it opens the app.
final class RideLiveActivityController {
    private var activity: Activity<RideActivityAttributes>?
    private var lastState: RideActivityAttributes.ContentState?
    private var lastPush = Date.distantPast
    private var lastStartAttempt = Date.distantPast
    private var pendingEnd: DispatchWorkItem?

    init() {
        // A previous run may have left one behind (e.g. the app was force-quit).
        let leftovers = Activity<RideActivityAttributes>.activities
        Task {
            for activity in leftovers {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    /// Call whenever the ride changes. Updates go out about once a second at most,
    /// since Live Activities aren't built for the radar's ten a second, except that a
    /// car turning red goes out straight away and expands the island, with the alert
    /// beep or, when `sound` is off, silently.
    func refresh(_ state: RideActivityAttributes.ContentState, sessionActive: Bool, alert: CarAlert?, sound: Bool) {
        guard sessionActive else {
            scheduleEnd()
            return
        }
        pendingEnd?.cancel()
        pendingEnd = nil

        guard let activity else {
            start(with: state)
            return
        }
        let sinceLastPush = Date().timeIntervalSince(lastPush)
        let due = sinceLastPush >= 1 && (state != lastState || sinceLastPush >= 60)
        guard alert != nil || due else { return }

        lastState = state
        lastPush = Date()
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(90))
        let alertConfiguration = alert.map {
            AlertConfiguration(title: "Car approaching",
                               body: LocalizedStringResource(stringLiteral: "\($0.distanceMeters) m behind, +\($0.closingKmh) km/h"),
                               sound: .named(sound ? "CarAlert.caf" : "Silence.caf"))
        }
        Task { await activity.update(content, alertConfiguration: alertConfiguration) }
    }

    private func start(with state: RideActivityAttributes.ContentState) {
        // Starting only works while the app is on screen; if it fails, the next
        // refresh a few seconds later simply tries again.
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              Date().timeIntervalSince(lastStartAttempt) >= 5 else { return }
        lastStartAttempt = Date()
        do {
            activity = try Activity.request(attributes: RideActivityAttributes(),
                                            content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(90)))
            lastState = state
            lastPush = Date()
        } catch {
            activity = nil
        }
    }

    /// Waits a little before ending, so a brief radar dropout doesn't make it flicker.
    private func scheduleEnd() {
        guard activity != nil, pendingEnd == nil else { return }
        let work = DispatchWorkItem { [weak self] in self?.end() }
        pendingEnd = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
    }

    private func end() {
        pendingEnd = nil
        guard let activity else { return }
        self.activity = nil
        lastState = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
