import Foundation
import SwiftData

/// One exercise performed within a session, holding its sets.
@Model
final class SessionExercise {
    @Attribute(.unique) var id: UUID
    /// Position within the session (0-based).
    var order: Int
    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.sessionExercise)
    var sets: [WorkoutSet] = []

    init(id: UUID = UUID(), order: Int, exercise: Exercise? = nil) {
        self.id = id
        self.order = order
        self.exercise = exercise
    }

    /// Sets sorted by `order`.
    var orderedSets: [WorkoutSet] {
        sets.sorted { $0.order < $1.order }
    }
}
