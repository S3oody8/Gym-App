import Foundation

/// Pure rule for what gets written to Apple Health for a finished session.
enum HealthWorkoutPlan {
    /// Start/end of the Health workout: the session's start to its finish time.
    /// nil when there's nothing meaningful to write (no sets, or no positive duration).
    static func interval(startedAt: Date, finishedAt: Date?, setCount: Int) -> DateInterval? {
        guard setCount > 0, let finishedAt, finishedAt > startedAt else { return nil }
        return DateInterval(start: startedAt, end: finishedAt)
    }
}
