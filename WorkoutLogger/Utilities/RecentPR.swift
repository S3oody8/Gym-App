import Foundation

/// One row of RECENT PRs: the exercise, the date and the set.
struct RecentPR: Equatable, Identifiable, Sendable {
    var id: UUID
    var exerciseName: String
    var date: Date
    var values: SetValues
}
