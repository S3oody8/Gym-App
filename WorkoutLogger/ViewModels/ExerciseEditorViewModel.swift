import Foundation
import Observation
import SwiftData

/// Drives the add/edit exercise form.
@MainActor
@Observable
final class ExerciseEditorViewModel {
    var draft: ExerciseDraft
    var saveErrorMessage: String?
    let exercise: Exercise?

    var isNew: Bool { exercise == nil }
    var title: String { isNew ? "New Exercise" : "Edit Exercise" }

    init(exercise: Exercise? = nil) {
        self.exercise = exercise
        if let exercise {
            draft = ExerciseDraft(
                name: exercise.name,
                equipment: exercise.equipment,
                incrementText: ExerciseDraft.format(exercise.weightIncrement)
            )
        } else {
            draft = ExerciseDraft()
        }
    }

    /// Names of every other exercise (archived included), for duplicate detection.
    func otherNames(from all: [Exercise]) -> [String] {
        all.filter { $0.id != exercise?.id }.map(\.name)
    }

    func validationError(among all: [Exercise]) -> ExerciseDraft.ValidationError? {
        draft.validate(existingNames: otherNames(from: all))
    }

    /// Writes the draft to the store. Returns false if invalid or if saving failed
    /// (then `saveErrorMessage` is set).
    @discardableResult
    func save(in context: ModelContext) -> Bool {
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        guard validationError(among: all) == nil, let increment = draft.increment else { return false }
        let target: Exercise
        if let exercise {
            target = exercise
        } else {
            target = Exercise(name: draft.trimmedName, equipment: draft.equipment)
            context.insert(target)
        }
        target.name = draft.trimmedName
        target.equipment = draft.equipment
        target.weightIncrement = increment
        do {
            try context.save()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            return false
        }
    }
}
