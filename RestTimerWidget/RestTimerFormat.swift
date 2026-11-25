import Foundation

/// "3:00" for an alert time in seconds.
enum RestTimerFormat {
    static func minutesSeconds(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
