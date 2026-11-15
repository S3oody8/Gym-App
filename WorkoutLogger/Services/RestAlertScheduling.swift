import Foundation

/// Schedules the single pending rest-alert notification.
@MainActor
protocol RestAlertScheduling {
    /// Replaces any pending rest alert with one at `date`.
    func schedule(at date: Date, restSeconds: Int)
    func cancel()
}
