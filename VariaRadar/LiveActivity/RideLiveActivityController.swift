import ActivityKit
import Foundation
import UIKit

/// Runs the ride's Live Activity (the Dynamic Island and the Lock Screen banner)
/// while the radar is connected or a Watch ride is in progress. Tapping it opens the app.
final class RideLiveActivityController {
    private var activity: Activity<RideActivityAttributes>?
    private var lastState: RideActivityAttributes.ContentState?
    private var lastPush = Date.distantPast
    private var lastStartAttempt = Date.distantPast
    private var pendingEnd: DispatchWorkItem?
    private var endTimeInBackground = UIBackgroundTaskIdentifier.invalid

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
            showLast(state)
            scheduleEnd()
            return
        }
        pendingEnd?.cancel()
        pendingEnd = nil
        releaseBackgroundTime()

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

    /// Ends it right away, e.g. when you leave the demo.
    func endNow() {
        end()
    }

    /// While the end is pending, shows what's left (usually no cars and no radar), so
    /// the island never shows cars that aren't there.
    private func showLast(_ state: RideActivityAttributes.ContentState) {
        guard let activity, let lastState,
              state.cars != lastState.cars || state.radarConnected != lastState.radarConnected else { return }
        self.lastState = state
        lastPush = Date()
        Task { await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(90))) }
    }

    /// Waits a little before ending, so a brief radar dropout doesn't make it flicker.
    /// The app is often in the background by then, so it asks iOS for the time; if iOS
    /// cuts that short, it ends straight away rather than leaving the island behind.
    private func scheduleEnd() {
        guard activity != nil, pendingEnd == nil else { return }
        var backgroundTime = UIBackgroundTaskIdentifier.invalid
        backgroundTime = UIApplication.shared.beginBackgroundTask { [weak self] in
            // iOS wants its time back: end now, and hand the time back before returning.
            self?.endTimeInBackground = .invalid
            self?.end()
            UIApplication.shared.endBackgroundTask(backgroundTime)
        }
        endTimeInBackground = backgroundTime
        let work = DispatchWorkItem { [weak self] in self?.end() }
        pendingEnd = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
    }

    private func end() {
        pendingEnd?.cancel()
        pendingEnd = nil
        // Keep the background time until the system has taken the activity down.
        let backgroundTime = endTimeInBackground
        endTimeInBackground = .invalid
        guard let activity else {
            Self.release(backgroundTime)
            return
        }
        self.activity = nil
        lastState = nil
        Task { @MainActor in
            await activity.end(nil, dismissalPolicy: .immediate)
            Self.release(backgroundTime)
        }
    }

    private func releaseBackgroundTime() {
        Self.release(endTimeInBackground)
        endTimeInBackground = .invalid
    }

    private static func release(_ backgroundTime: UIBackgroundTaskIdentifier) {
        if backgroundTime != .invalid { UIApplication.shared.endBackgroundTask(backgroundTime) }
    }
}
