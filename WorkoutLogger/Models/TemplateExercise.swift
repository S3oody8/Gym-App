import Foundation
import SwiftData

/// One exercise slot in a template, with its position.
@Model
final class TemplateExercise {
    @Attribute(.unique) var id: UUID
    /// Position within the template (0-based).
    var order: Int
    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(id: UUID = UUID(), order: Int, exercise: Exercise? = nil) {
        self.id = id
        self.order = order
        self.exercise = exercise
    }
}
