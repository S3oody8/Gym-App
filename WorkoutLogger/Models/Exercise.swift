import Foundation
import SwiftData

/// A user-defined exercise. Variants are separate exercises.
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Primary muscle group name (free-form string; list defined in a later step).
    var primaryMuscle: String
    /// Secondary muscle group names.
    var secondaryMuscles: [String]
    /// Raw value of `Equipment`.
    var equipmentRaw: String
    /// Weight step in kg used by the ± buttons.
    var weightIncrement: Double
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \SessionExercise.exercise)
    var sessionEntries: [SessionExercise] = []

    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateEntries: [TemplateExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscle: String,
        secondaryMuscles: [String] = [],
        equipment: Equipment,
        weightIncrement: Double = 2.5,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipmentRaw = equipment.rawValue
        self.weightIncrement = weightIncrement
        self.createdAt = createdAt
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .machine }
        set { equipmentRaw = newValue.rawValue }
    }
}
