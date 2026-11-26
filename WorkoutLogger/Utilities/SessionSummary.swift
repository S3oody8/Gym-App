import Foundation

/// What a history row shows for one session: set count, volume (kg) and duration.
struct SessionSummary: Equatable, Sendable {
    var sets: Int
    var volume: Double
    var duration: TimeInterval

    static let empty = SessionSummary(sets: 0, volume: 0, duration: 0)

    /// Volume over all sets (working and drop); duration from the first set to the last.
    init(values: [SetValues], times: [Date]) {
        sets = values.count
        volume = SessionMetrics.load(values)
        if let first = times.min(), let last = times.max() {
            duration = last.timeIntervalSince(first)
        } else {
            duration = 0
        }
    }

    init(sets: Int, volume: Double, duration: TimeInterval) {
        self.sets = sets
        self.volume = volume
        self.duration = duration
    }
}
