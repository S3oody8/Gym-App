import Foundation
import Observation
import SwiftData

/// Search plus delete / archive actions for the exercise library.
@MainActor
@Observable
final class ExerciseLibraryViewModel {
    var searchText: String = ""
    var showArchived: Bool = false
    var saveErrorMessage: String?

    func visibleActive(_ all: [Exercise]) -> [Exercise] {
        ExerciseSearch.filter(all, query: searchText, name: \.name, isArchived: \.isArchived)
    }

    /// Archived exercises are only listed when not searching (search hides them).
    func visibleArchived(_ all: [Exercise]) -> [Exercise] {
        guard showArchived, searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return all.filter(\.isArchived)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Deletes an exercise only if it has no history. Returns false otherwise or on save failure.
    @discardableResult
    func delete(_ exercise: Exercise, in context: ModelContext) -> Bool {
        guard !exercise.hasHistory else { return false }
        for item in exercise.templateEntries {
            context.delete(item)
        }
        context.delete(exercise)
        return persist(context)
    }

    @discardableResult
    func setArchived(_ archived: Bool, for exercise: Exercise, in context: ModelContext) -> Bool {
        exercise.isArchived = archived
        return persist(context)
    }

    private func persist(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            return false
        }
    }
}
