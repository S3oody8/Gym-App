import Foundation

/// A fully resolved import: workouts → exercises (by target name) → sets in kg.
struct ShrugPlan: Equatable, Sendable {
    struct Workout: Equatable, Sendable {
        var id: UUID
        var start: Date
        var entries: [Entry]
    }

    struct Entry: Equatable, Sendable {
        var id: UUID
        var order: Int
        var exerciseName: String
        var sets: [PlannedSet]
    }

    struct PlannedSet: Equatable, Sendable {
        var id: UUID
        var order: Int
        var weight: Double
        var reps: Int
    }

    var workouts: [Workout]
    /// Target exercise names used by the plan (unique, first-seen order).
    var exerciseNames: [String]
    /// Timed rows skipped, per Shrug exercise name.
    var skippedTimed: [String: Int]
    var setCount: Int { workouts.reduce(0) { $0 + $1.entries.reduce(0) { $0 + $1.sets.count } } }
}
