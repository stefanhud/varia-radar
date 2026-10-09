import Foundation
import WatchConnectivity

/// On first launch, turns the Apple Watch features off when no Watch is paired (or on
/// an iPad), so a radar-only rider doesn't get Watch buttons that can't work.
final class WatchPairingCheck: NSObject, WCSessionDelegate {
    static let shared = WatchPairingCheck()
    private static let doneKey = "checkedForPairedWatch"

    func runOnce() {
        guard !UserDefaults.standard.bool(forKey: Self.doneKey) else { return }
        guard WCSession.isSupported() else {
            finish(watchPaired: false)
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func finish(watchPaired: Bool) {
        UserDefaults.standard.set(true, forKey: Self.doneKey)
        if !watchPaired { AppSettings.turnOffWatchUnlessChosen() }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        guard state == .activated else { return }
        let paired = session.isPaired
        DispatchQueue.main.async { self.finish(watchPaired: paired) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
