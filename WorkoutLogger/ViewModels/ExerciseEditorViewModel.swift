import Foundation
import Observation
import SwiftData

/// Drives the add/edit exercise form.
@MainActor
@Observable
final class ExerciseEditorViewModel {
    var draft: ExerciseDraft
    private let exercise: Exercise?

    var isNew: Bool { exercise == nil }
    var title: String { isNew ? "New Exercise" : "Edit Exercise" }

    init(exercise: Exercise? = nil) {
        self.exercise = exercise
        if let exercise {
            draft = ExerciseDraft(
                name: exercise.name,
                primary: exercise.primary,
                secondary: Set(exercise.secondary),
                equipment: exercise.equipment,
                incrementText: ExerciseDraft.format(exercise.weightIncrement)
            )
        } else {
            draft = ExerciseDraft()
        }
    }

    /// Writes the draft to the store. Returns false if the draft is invalid.
    @discardableResult
    func save(in context: ModelContext) -> Bool {
        guard draft.isValid, let increment = draft.increment else { return false }
        let target: Exercise
        if let exercise {
            target = exercise
        } else {
            target = Exercise(name: draft.trimmedName, primary: draft.primary, equipment: draft.equipment)
            context.insert(target)
        }
        target.name = draft.trimmedName
        target.primary = draft.primary
        target.secondary = draft.cleanedSecondary
        target.equipment = draft.equipment
        target.weightIncrement = increment
        try? context.save()
        return true
    }
}
