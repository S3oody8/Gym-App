import Foundation
import Observation
import SwiftData

/// History on the Workouts tab: PR counts, and deleting a whole session with undo.
@MainActor
@Observable
final class HistoryViewModel {
    private(set) var deletedSnapshot: SessionSnapshot?
    var saveErrorMessage: String?
    private var toastTask: Task<Void, Never>?

    /// Number of PR sets per session id, computed once over every exercise's history.
    func prCounts(exercises: [Exercise], sessions: [WorkoutSession]) -> [UUID: Int] {
        var badges: [UUID: PRBadges] = [:]
        for exercise in exercises {
            badges.merge(PRDetector.badges(for: ProgressQueries.prInputs(for: exercise))) { a, _ in a }
        }
        var setSessions: [UUID: UUID] = [:]
        for session in sessions {
            for set in session.allSets { setSessions[set.id] = session.id }
        }
        return PRCounter.countsBySession(badges: badges, setSessions: setSessions)
    }

    func delete(_ session: WorkoutSession, in context: ModelContext) {
        do {
            let snapshot = try WorkoutStore(context: context).deleteSession(session)
            showUndo(snapshot)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    func undoDelete(in context: ModelContext) {
        guard let snapshot = deletedSnapshot else { return }
        dismissUndo()
        do {
            try WorkoutStore(context: context).restoreSession(snapshot)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    func dismissUndo() {
        toastTask?.cancel()
        deletedSnapshot = nil
    }

    private func showUndo(_ snapshot: SessionSnapshot) {
        toastTask?.cancel()
        deletedSnapshot = snapshot
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: SessionEditorViewModel.toastDuration)
            guard !Task.isCancelled else { return }
            self?.deletedSnapshot = nil
        }
    }
}
