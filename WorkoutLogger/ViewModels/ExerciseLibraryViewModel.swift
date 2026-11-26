import Foundation
import Observation
import SwiftData

/// Search plus delete / archive actions for the exercise library.
@MainActor
@Observable
final class ExerciseLibraryViewModel {
    var searchText: String = ""
    var saveErrorMessage: String?

    var isSearching: Bool { !ExerciseSearch.words(searchText).isEmpty }

    /// Not searching: last used first, then by name. Searching: search ranking (SPEC §1).
    /// `lastUsed` should be a cached lookup (`PRCache.lastUsed`), not the model walk.
    func visibleActive(_ all: [Exercise], lastUsed: (Exercise) -> Date? = { $0.lastUsed }) -> [Exercise] {
        guard isSearching else {
            return ExerciseOrdering.recentFirst(all.filter { !$0.isArchived }, lastUsed: lastUsed, name: \.name)
        }
        return ExerciseSearch.filter(all, query: searchText, name: \.name, isArchived: \.isArchived)
    }

    /// Archived exercises, in their own section at the bottom. Search hides them.
    func visibleArchived(_ all: [Exercise], lastUsed: (Exercise) -> Date? = { $0.lastUsed }) -> [Exercise] {
        guard !isSearching else { return [] }
        return ExerciseOrdering.recentFirst(all.filter(\.isArchived), lastUsed: lastUsed, name: \.name)
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
