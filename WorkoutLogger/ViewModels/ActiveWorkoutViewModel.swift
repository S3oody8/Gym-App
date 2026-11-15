import Foundation
import Observation
import SwiftData

/// Drives the active workout screen: adding exercises and sets, the set pop-up, undo,
/// and surfacing failed saves.
@MainActor
@Observable
final class ActiveWorkoutViewModel {
    let session: WorkoutSession
    private let store: WorkoutStore
    private let restAlerts: RestAlertScheduling
    private let settings: () -> RestAlertSettings

    /// Last undoable action, shown in the toast while non-nil.
    private(set) var undoAction: WorkoutUndoAction?
    /// Set when a save fails. The change is kept in memory; Retry tries again.
    var saveErrorMessage: String?
    /// Incremented whenever a set is added (drives haptic feedback).
    private(set) var addedSetCount = 0
    /// Non-nil while the set pop-up is open.
    var entryRequest: SetEntryRequest?

    private var lastSessionCache: [UUID: [SetValues]] = [:]
    private var toastTask: Task<Void, Never>?
    static let toastDuration: Duration = .seconds(5)

    init(
        session: WorkoutSession,
        context: ModelContext,
        restAlerts: RestAlertScheduling? = nil,
        settings: @escaping () -> RestAlertSettings = { RestAlertSettings.current() }
    ) {
        self.session = session
        self.store = WorkoutStore(context: context)
        self.restAlerts = restAlerts ?? RestAlertNotifier.shared
        self.settings = settings
    }

    var totalSets: Int { session.allSets.count }

    // MARK: Rest timer

    /// Time the most recent set was logged; the rest stopwatch counts up from here.
    var lastSetAt: Date? {
        session.allSets.map(\.loggedAt).max()
    }

    /// Re-aligns the pending rest alert with the latest set (after add / delete / undo),
    /// using the current settings. Edits don't call this, so settings changes only take
    /// effect from the next rest period.
    private func syncRestAlert(now: Date = .now) {
        let current = settings()
        if let date = RestTimerMath.fireDate(lastSetAt: lastSetAt, alertSeconds: current.seconds,
                                             enabled: current.enabled, now: now) {
            restAlerts.schedule(at: date, restSeconds: current.seconds)
        } else {
            restAlerts.cancel()
        }
    }

    // MARK: Lookups

    /// Sets from the previous session containing this entry's exercise (cached per workout).
    func lastSessionSets(for entry: SessionExercise) -> [SetValues] {
        guard let exercise = entry.exercise else { return [] }
        if let cached = lastSessionCache[exercise.id] { return cached }
        let sets = WorkoutStore.lastSessionSets(for: exercise, before: session)
        lastSessionCache[exercise.id] = sets
        return sets
    }

    /// "Last: 80×8" text for the set at `index`, or nil.
    func lastText(for entry: SessionExercise, index: Int) -> String? {
        SetPlanner.matchingLast(index: index, in: lastSessionSets(for: entry))
            .map { "Last: " + WeightFormatter.compact(weight: $0.weight, reps: $0.reps) }
    }

    func canQuickAdd(_ entry: SessionExercise) -> Bool {
        !entry.sets.isEmpty
    }

    // MARK: Exercises

    func addExercise(_ exercise: Exercise) {
        perform {
            let entry = try store.addEntry(exercise, to: session)
            showUndo(.addedEntry(entryID: entry.id))
        }
    }

    func removeEntry(_ entry: SessionExercise) {
        perform {
            let snapshot = try store.remove(entry, from: session)
            showUndo(.removedEntry(snapshot))
        }
        syncRestAlert()
    }

    // MARK: Sets

    func quickAdd(to entry: SessionExercise, minus: Int) {
        guard let previous = entry.orderedSets.last?.values else { return }
        addSet(SetPlanner.quickSet(from: previous, minus: minus), to: entry)
    }

    func openAddSet(for entry: SessionExercise) {
        let initial = SetPlanner.prefill(
            sessionSets: entry.orderedSets.map(\.values),
            historySets: lastSessionSets(for: entry)
        )
        entryRequest = SetEntryRequest(
            entryID: entry.id, setID: nil,
            exerciseName: entry.exercise?.name ?? "Exercise",
            initial: initial,
            increment: entry.exercise?.weightIncrement ?? 2.5
        )
    }

    func openEdit(_ set: WorkoutSet, in entry: SessionExercise) {
        entryRequest = SetEntryRequest(
            entryID: entry.id, setID: set.id,
            exerciseName: entry.exercise?.name ?? "Exercise",
            initial: set.values,
            increment: entry.exercise?.weightIncrement ?? 2.5
        )
    }

    /// Called by the pop-up's Save button.
    func submit(_ values: SetValues, for request: SetEntryRequest) {
        entryRequest = nil
        guard let entry = entry(withID: request.entryID) else { return }
        if let setID = request.setID {
            guard let set = entry.sets.first(where: { $0.id == setID }) else { return }
            perform {
                let previous = try store.update(set, to: values)
                showUndo(.editedSet(setID: setID, previous: previous))
            }
        } else {
            addSet(values, to: entry)
        }
    }

    func deleteSet(_ set: WorkoutSet, from entry: SessionExercise) {
        perform {
            let snapshot = try store.delete(set, from: entry)
            showUndo(.deletedSet(entryID: entry.id, snapshot: snapshot))
        }
        syncRestAlert()
    }

    private func addSet(_ values: SetValues, to entry: SessionExercise) {
        perform {
            let set = try store.addSet(values, to: entry)
            addedSetCount += 1
            showUndo(.addedSet(setID: set.id))
        }
        syncRestAlert()
    }

    // MARK: Undo

    func undo() {
        guard let action = undoAction else { return }
        dismissUndo()
        perform {
            switch action {
            case .addedSet(let setID):
                if let (set, entry) = findSet(setID) { try store.delete(set, from: entry) }
            case .editedSet(let setID, let previous):
                if let (set, _) = findSet(setID) { try store.update(set, to: previous) }
            case .deletedSet(let entryID, let snapshot):
                if let entry = entry(withID: entryID) { try store.restore(snapshot, into: entry) }
            case .addedEntry(let entryID):
                if let entry = entry(withID: entryID) { try store.remove(entry, from: session) }
            case .removedEntry(let snapshot):
                try store.restore(snapshot, into: session)
            }
        }
        syncRestAlert()
    }

    func dismissUndo() {
        toastTask?.cancel()
        undoAction = nil
    }

    private func showUndo(_ action: WorkoutUndoAction) {
        toastTask?.cancel()
        undoAction = action
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: Self.toastDuration)
            guard !Task.isCancelled else { return }
            self?.undoAction = nil
        }
    }

    // MARK: Finish

    func finish() {
        restAlerts.cancel()
        perform { try store.finish(session) }
    }

    func discard() {
        restAlerts.cancel()
        perform { try store.discard(session) }
    }

    // MARK: Persistence

    func retrySave() {
        saveErrorMessage = nil
        perform { try store.save() }
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func entry(withID id: UUID) -> SessionExercise? {
        session.entries.first { $0.id == id }
    }

    private func findSet(_ id: UUID) -> (WorkoutSet, SessionExercise)? {
        for entry in session.entries {
            if let set = entry.sets.first(where: { $0.id == id }) { return (set, entry) }
        }
        return nil
    }
}
