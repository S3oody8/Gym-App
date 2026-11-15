import Foundation

/// Formats a session duration, e.g. "52 min", "1 h 05 min".
enum DurationFormatter {
    static func string(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        if minutes < 60 { return "\(minutes) min" }
        return String(format: "%d h %02d min", minutes / 60, minutes % 60)
    }
}
