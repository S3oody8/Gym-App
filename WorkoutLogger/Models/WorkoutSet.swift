import Foundation
import SwiftData

/// A single logged set.
@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    /// Position within the exercise (0-based).
    var order: Int
    /// Weight in kg.
    var weight: Double
    var reps: Int
    /// Reps in reserve, 0–5, optional.
    var rir: Int?
    /// Raw value of `SetType`.
    var typeRaw: String
    /// When the set was logged. Drives session duration and the rest timer.
    var loggedAt: Date
    var sessionExercise: SessionExercise?

    init(
        id: UUID = UUID(),
        order: Int,
        weight: Double,
        reps: Int,
        rir: Int? = nil,
        type: SetType = .working,
        loggedAt: Date = .now
    ) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.typeRaw = type.rawValue
        self.loggedAt = loggedAt
    }

    var type: SetType {
        get { SetType(rawValue: typeRaw) ?? .working }
        set { typeRaw = newValue.rawValue }
    }

    var values: SetValues {
        get { SetValues(weight: weight, reps: reps, rir: rir, type: type) }
        set {
            weight = newValue.weight
            reps = newValue.reps
            rir = newValue.rir
            type = newValue.type
        }
    }
}
