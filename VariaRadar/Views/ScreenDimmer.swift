import UIKit

/// Dims the screen while the road behind is quiet, and brings it straight back when a
/// car approaches or you touch the screen. iOS itself restores your brightness when
/// you leave the app.
final class ScreenDimmer {
    private let quietDelay: TimeInterval = 15
    private let dimmedFraction: CGFloat = 0.25
    private var normalBrightness: CGFloat?   // set while dimmed
    private var quietSince = Date()
    private var ramp: Timer?

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }

    /// Call often; every radar update is fine.
    func update(enabled: Bool, carApproaching: Bool) {
        guard UIApplication.shared.applicationState == .active else { return }
        guard enabled else {
            quietSince = Date()
            wake()
            return
        }
        if carApproaching {
            quietSince = Date()
            wake()
        } else if normalBrightness == nil, Date().timeIntervalSince(quietSince) >= quietDelay {
            dim()
        }
    }

    /// A touch on the screen: wake up and start the quiet period over.
    func touched() {
        quietSince = Date()
        wake()
    }

    /// The app left the screen and iOS restored the brightness, so forget ours.
    func reset() {
        ramp?.invalidate()
        normalBrightness = nil
        quietSince = Date()
    }

    private func dim() {
        guard let screen else { return }
        normalBrightness = screen.brightness
        fade(to: screen.brightness * dimmedFraction)
    }

    private func wake() {
        guard let normal = normalBrightness else { return }
        normalBrightness = nil
        fade(to: normal)
    }

    private func fade(to target: CGFloat) {
        guard let screen else { return }
        ramp?.invalidate()
        let start = screen.brightness
        let steps = 10
        var step = 0
        ramp = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            step += 1
            screen.brightness = start + (target - start) * CGFloat(step) / CGFloat(steps)
            if step >= steps { timer.invalidate() }
        }
    }
}
