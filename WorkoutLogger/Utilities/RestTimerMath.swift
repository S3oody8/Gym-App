import Foundation

/// Pure rest-timer rules: elapsed time, alert fire date, alert-time picker values.
enum RestTimerMath {
    static let minAlertSeconds = 30
    static let maxAlertSeconds = 600
    static let stepSeconds = 15

    /// Seconds since the last set (0 if none or clock went backwards).
    static func elapsed(since lastSetAt: Date?, now: Date) -> TimeInterval {
        guard let lastSetAt else { return 0 }
        return max(0, now.timeIntervalSince(lastSetAt))
    }

    /// When the rest alert should fire, or nil if disabled, no set yet, or already past.
    static func fireDate(lastSetAt: Date?, alertSeconds: Int, enabled: Bool, now: Date) -> Date? {
        guard enabled, let lastSetAt else { return nil }
        let date = lastSetAt.addingTimeInterval(TimeInterval(alertSeconds))
        return date > now ? date : nil
    }

    /// Rest ring progress: elapsed ÷ alert time, from 0 to 1 (capped at 1).
    static func progress(since start: Date, alertSeconds: Int, now: Date) -> Double {
        guard alertSeconds > 0 else { return 1 }
        return min(1, elapsed(since: start, now: now) / Double(alertSeconds))
    }

    /// −30 s / +30 s on this rest period's alert time: stays within 0:30–10:00 and never goes
    /// below the time already elapsed (rounded up to whole seconds). Once more than 10:00 has
    /// elapsed the alert time no longer changes.
    static func adjustedAlert(_ alertSeconds: Int, by delta: Int, elapsed: TimeInterval) -> Int {
        let floorSeconds = Int(elapsed.rounded(.up))
        guard floorSeconds <= maxAlertSeconds else { return alertSeconds }
        let moved = min(maxAlertSeconds, max(minAlertSeconds, alertSeconds + delta))
        return max(moved, floorSeconds)
    }

    /// Snaps to the 15 s grid and clamps to 0:30–10:00.
    static func clampAlert(_ seconds: Int) -> Int {
        let snapped = Int((Double(seconds) / Double(stepSeconds)).rounded()) * stepSeconds
        return min(maxAlertSeconds, max(minAlertSeconds, snapped))
    }

    /// Combines the minute and second wheels into a valid alert time.
    static func alertSeconds(minutes: Int, seconds: Int) -> Int {
        clampAlert(minutes * 60 + seconds)
    }

    /// "m:ss", e.g. 0 → "0:00", 135 → "2:15", 3725 → "62:05".
    static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
