import Foundation
import Observation
import SwiftData

/// Edits a session — the live workout or a finished one from History: adding exercises and
/// sets, the set pop-up, undo, moving the date/time, saving as a template, and surfacing
/// failed saves. Rest alerts are only managed for the live workout.
@MainActor
@Observable
final class SessionEditorViewModel {
    let session: WorkoutSession
    private let store: WorkoutStore
    /// Rest period, alert, Skip and Live Activity (shared with the mini-bar).
    let restTimer: RestTimerStore
    private let health: WorkoutHealthExporting
    private let healthEnabled: () -> Bool
    private let quickButtonValues: () -> [Int]

    /// Last undoable action, shown in the toast while non-nil.
    private(set) var undoAction: WorkoutUndoAction?
    /// Set when a save fails. The change is kept in memory; Retry tries again.
    var saveErrorMessage: String?
    /// Incremented whenever a set is added (drives haptic feedback).
    private(set) var addedSetCount = 0
    /// Non-nil while the set pop-up is open.
    var entryRequest: SetEntryRequest?

    /// The workout name as typed. Saved `nameSaveDelay` after the last keystroke, on Return,
    /// when leaving the screen and before Finish, not on every keystroke (SPEC §2).
    private(set) var nameDraft: String

    private var lastSessionCache: [UUID: [SetValues]] = [:]
    private var toastTask: Task<Void, Never>?
    private var nameSaveTask: Task<Void, Never>?
    static let toastDuration: Duration = .seconds(5)
    static let nameSaveDelay: Duration = .milliseconds(500)

    init(
        session: WorkoutSession,
        context: ModelContext,
        restAlerts: RestAlertScheduling? = nil,
        settings: @escaping () -> RestAlertSettings = { RestAlertSettings.current() },
        restTimer: RestTimerStore? = nil,
        health: WorkoutHealthExporting? = nil,
        healthEnabled: @escaping () -> Bool = { HealthSync.isEnabled },
        quickButtons: @escaping () -> [Int] = { QuickButtons.current() }
    ) {
        self.quickButtonValues = quickButtons
        self.health = health ?? HealthSync.shared
        self.healthEnabled = healthEnabled
        self.session = session
        self.nameDraft = session.name
        self.store = WorkoutStore(context: context)
        // Tests pass fake alerts: they get their own timer that isn't saved to UserDefaults.
        self.restTimer = restTimer ?? (restAlerts.map {
            RestTimerStore(alerts: $0, settings: settings, defaults: nil)
        } ?? .shared)
    }

    var totalSets: Int { session.allSets.count }

    /// True for the in-progress workout, false for a finished session being edited.
    var isLive: Bool { session.isActive }

    // MARK: Rest timer

    /// Time the most recent set was logged; the rest stopwatch counts up from here.
    var lastSetAt: Date? {
        session.allSets.map(\.loggedAt).max()
    }

    /// The rest period to show (nil before the first set and after Skip).
    var restPeriod: RestPeriod? {
        isLive ? restTimer.visiblePeriod(for: session.id) : nil
    }

    /// Re-aligns the rest period with the latest set (after add / delete / undo). A new latest
    /// set starts a new period with the current settings; edits don't call this, so settings
    /// changes only take effect from the next rest period.
    private func syncRestAlert(now: Date = .now) {
        guard isLive else { return }
        restTimer.sync(sessionID: session.id, lastSetAt: lastSetAt, now: now)
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

    /// The current exercise: the one with the most recent set (live workout only).
    func isCurrent(_ entry: SessionExercise) -> Bool {
        guard isLive, let latest = lastSetAt else { return false }
        let currentID = session.entries.first { $0.sets.contains { $0.loggedAt == latest } }?.id
        return entry.id == currentID
    }

    /// The "Repeat" quick buttons from Settings (e.g. [1, 2, 3]).
    var quickButtons: [Int] { quickButtonValues() }

    /// PR badges for this entry's sets, computed from the exercise's whole history so edits
    /// anywhere are reflected immediately.
    func prBadges(for entry: SessionExercise) -> [UUID: PRBadges] {
        guard let exercise = entry.exercise else { return [:] }
        return PRDetector.badges(for: ProgressQueries.prInputs(for: exercise))
    }

    func canQuickAdd(_ entry: SessionExercise) -> Bool {
        !entry.sets.isEmpty
    }

    // MARK: Exercises

    /// Adds the exercise to the session and returns the new entry's id (nil if saving failed).
    @discardableResult
    func addExercise(_ exercise: Exercise) -> UUID? {
        var id: UUID?
        perform {
            let entry = try store.addEntry(exercise, to: session)
            showUndo(.addedEntry(entryID: entry.id))
            id = entry.id
        }
        return id
    }

    /// Opens the set pad for a newly added entry (called once the picker has closed).
    func openAddSet(forEntryID id: UUID) {
        guard let entry = entry(withID: id) else { return }
        openAddSet(for: entry)
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
            // A set added to a past session gets that session's latest set time, so its
            // duration isn't stretched to "now".
            let date = isLive ? Date.now : (lastSetAt ?? session.startedAt)
            let set = try store.addSet(values, to: entry, at: date)
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
            case .movedSession(let previousStart):
                try store.move(session, toStart: previousStart)
            case .savedTemplate(let templateID):
                try store.deleteTemplate(withID: templateID)
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

    // MARK: Date / template

    /// Moves the session (and all its set times) so it starts at `date`. Duration is unchanged.
    func moveStart(to date: Date) {
        let previous = session.startedAt
        guard date != previous else { return }
        perform {
            try store.move(session, toStart: date)
            showUndo(.movedSession(previousStart: previous))
        }
    }

    var canSaveTemplate: Bool {
        session.entries.contains { $0.exercise != nil }
    }

    func saveTemplate(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        perform {
            let template = try store.saveTemplate(from: session, name: trimmed)
            showUndo(.savedTemplate(templateID: template.id))
        }
    }

    // MARK: Finish

    /// True when Finish should first ask for a name.
    var needsNameBeforeFinish: Bool {
        nameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Finishes the workout, optionally naming it first (nil = keep the current name / Skip).
    func finish(naming name: String? = nil) {
        restTimer.end()
        commitName()
        perform {
            if let name { try store.rename(session, to: name.trimmingCharacters(in: .whitespacesAndNewlines)) }
            try store.finish(session)
        }
        guard !session.isActive else { return }
        let (start, end, sets) = (session.startedAt, session.finishedAt, totalSets)
        let health = health, enabled = healthEnabled()
        healthTask = Task { await HealthSync.export(startedAt: start, finishedAt: end, setCount: sets,
                                                    exporter: health, enabled: enabled) }
    }

    /// The Health export started by the last `finish` (exposed for tests).
    private(set) var healthTask: Task<Void, Never>?

    /// Saves the workout name as typed (trimmed only for display / on Finish). Not part of undo.
    func rename(to name: String) {
        nameSaveTask?.cancel()
        nameDraft = name
        guard name != session.name else { return }
        perform { try store.rename(session, to: name) }
    }

    /// Called on every keystroke: keeps the text and saves it once typing pauses.
    func editName(_ text: String) {
        nameDraft = text
        nameSaveTask?.cancel()
        nameSaveTask = Task { [weak self] in
            try? await Task.sleep(for: Self.nameSaveDelay)
            guard !Task.isCancelled else { return }
            self?.commitName()
        }
    }

    /// Saves a pending name edit now (Return, leaving the screen, Finish).
    func commitName() {
        nameSaveTask?.cancel()
        nameSaveTask = nil
        rename(to: nameDraft)
    }

    func discard() {
        restTimer.end()
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
