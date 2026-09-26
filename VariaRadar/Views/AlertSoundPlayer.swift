import AVFoundation

/// Plays the short rising two-tone alert when a car turns red while the app is on
/// screen. Outside the app, the Dynamic Island alert plays the same sound.
///
/// Switching the audio session on and off can take a moment, so it never happens on
/// the main thread: a stutter would hit the radar exactly when a car turns red.
final class AlertSoundPlayer {
    private let player: AVAudioPlayer?
    private let audioQueue = DispatchQueue(label: "AlertSoundPlayer.audio")
    private var pendingDeactivation: DispatchWorkItem?

    init() {
        player = Bundle.main.url(forResource: "CarAlert", withExtension: "caf")
            .flatMap { try? AVAudioPlayer(contentsOf: $0) }
        audioQueue.async {
            // It's a safety alert, so it plays even with the phone on silent, and it only
            // turns music down for a moment instead of stopping it.
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
        }
    }

    func play() {
        guard let player else { return }
        pendingDeactivation?.cancel()   // a second red car shouldn't cut its own beep short
        audioQueue.async { [weak self] in
            AVAudioSession.sharedInstance().activate(options: []) { activated, _ in
                guard activated else { return }
                DispatchQueue.main.async {
                    player.currentTime = 0
                    player.play()
                    self?.scheduleDeactivation()
                }
            }
        }
    }

    /// Hands the audio back, and music back to full volume, once the beep is over.
    private func scheduleDeactivation() {
        let work = DispatchWorkItem {
            AVAudioSession.sharedInstance().deactivate(options: .notifyOthersOnDeactivation) { _, _ in }
        }
        pendingDeactivation = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }
}
