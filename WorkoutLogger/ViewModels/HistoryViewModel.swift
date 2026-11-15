import Foundation
import Observation
import SwiftData

/// History list: delete a whole session with undo.
@MainActor
@Observable
final class HistoryViewModel {
    private(set) var deletedSnapshot: SessionSnapshot?
    var saveErrorMessage: String?
    private var toastTask: Task<Void, Never>?

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
