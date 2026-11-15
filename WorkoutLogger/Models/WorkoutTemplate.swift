import Foundation
import SwiftData

/// A named, ordered list of exercises. Starting from a template creates no sets.
@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var items: [TemplateExercise] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }

    /// Items sorted by `order`.
    var orderedItems: [TemplateExercise] {
        items.sorted { $0.order < $1.order }
    }
}
