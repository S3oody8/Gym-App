import Foundation
import SwiftData

/// A workout session, built live. Holds its exercises in performed order.
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    /// User-given name, e.g. "Anterior". Empty if not named.
    var name: String = ""
    /// When the session was started (editable for past sessions).
    var startedAt: Date
    /// Set when the user finishes the session. `nil` means the workout is still active.
    var finishedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var entries: [SessionExercise] = []

    init(id: UUID = UUID(), name: String = "", startedAt: Date = .now, finishedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }

    var isActive: Bool { finishedAt == nil }

    /// Exercises sorted by `order`.
    var orderedEntries: [SessionExercise] {
        entries.sorted { $0.order < $1.order }
    }

    /// All sets in the session.
    var allSets: [WorkoutSet] {
        entries.flatMap(\.sets)
    }

    /// Total volume in kg: weight × reps over all sets (working and drop).
    var load: Double {
        SessionMetrics.load(allSets.map(\.values))
    }

    /// Duration from the first set logged to the last (0 if fewer than two sets).
    var duration: TimeInterval {
        let times = allSets.map(\.loggedAt)
        guard let first = times.min(), let last = times.max() else { return 0 }
        return last.timeIntervalSince(first)
    }
}
