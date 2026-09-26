import Foundation

enum RideFormat {
    /// 1:03:12 for rides over an hour, 4:05 otherwise.
    static func duration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    /// Apple's effort scale: 1–3 easy, 4–6 moderate, 7–8 hard, 9–10 all out.
    static func effortLabel(_ score: Int) -> String {
        switch score {
        case ...3:  return "Easy"
        case 4...6: return "Moderate"
        case 7...8: return "Hard"
        default:    return "All out"
        }
    }
}
