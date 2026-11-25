import Foundation
import SwiftData

/// A user-defined exercise. Variants are separate exercises.
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Raw value of `Equipment`.
    var equipmentRaw: String
    /// Weight step in kg used by the ± buttons.
    var weightIncrement: Double
    var createdAt: Date
    /// Archived exercises are hidden from pickers and search; history is kept.
    var isArchived: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \SessionExercise.exercise)
    var sessionEntries: [SessionExercise] = []

    @Relationship(deleteRule: .nullify, inverse: \TemplateExercise.exercise)
    var templateEntries: [TemplateExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        equipment: Equipment,
        weightIncrement: Double = 2.5,
        createdAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.equipmentRaw = equipment.rawValue
        self.weightIncrement = weightIncrement
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .machine }
        set { equipmentRaw = newValue.rawValue }
    }

    /// True if the exercise appears in any session. Such exercises can be archived but not deleted.
    var hasHistory: Bool { !sessionEntries.isEmpty }

    /// Start of the most recent session with at least one set of this exercise (not stored).
    var lastUsed: Date? {
        sessionEntries.filter { !$0.sets.isEmpty }.compactMap { $0.session?.startedAt }.max()
    }
}
