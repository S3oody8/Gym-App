import Foundation

/// One rest period: from the last logged set until the next one. Stored in UserDefaults so
/// the alert time for this period survives minimising the workout and relaunching.
struct RestPeriod: Codable, Equatable, Sendable {
    var sessionID: UUID
    /// Time of the set that started this rest period.
    var start: Date
    /// When the alert fires, in seconds after `start` (0:30–10:00, moved with ±30 s).
    var alertSeconds: Int
    /// True after Skip rest: the timer is hidden and its alert cancelled until the next set.
    var skipped: Bool = false

    var alertDate: Date { start.addingTimeInterval(TimeInterval(alertSeconds)) }
}
