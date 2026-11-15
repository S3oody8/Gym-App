import Foundation
@testable import WorkoutLogger

/// Records rest-alert scheduling calls instead of posting notifications.
@MainActor
final class FakeRestAlerts: RestAlertScheduling {
    private(set) var scheduled: [(date: Date, seconds: Int)] = []
    private(set) var cancelCount = 0
    /// The currently pending alert, if any.
    private(set) var pending: Date?

    func schedule(at date: Date, restSeconds: Int) {
        scheduled.append((date, restSeconds))
        pending = date
    }

    func cancel() {
        cancelCount += 1
        pending = nil
    }
}
