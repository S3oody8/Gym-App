import Foundation
import SwiftData

/// All workout mutations. Every mutating call saves immediately (crash safety) and throws if
/// the save fails; the in-memory change is kept so a retry can persist it.
@MainActor
struct WorkoutStore {
    let context: ModelContext

    func save() throws {
        try context.save()
    }

    // MARK: Sessions

    func activeSession() -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.finishedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    func startSession(at date: Date = .now) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: date)
        context.insert(session)
        try save()
        return session
    }

    func finish(_ session: WorkoutSession, at date: Date = .now) throws {
        session.finishedAt = date
        try save()
    }

    func discard(_ session: WorkoutSession) throws {
        context.delete(session)
        try save()
    }

    // MARK: Entries

    @discardableResult
    func addEntry(_ exercise: Exercise, to session: WorkoutSession) throws -> SessionExercise {
        let order = (session.entries.map(\.order).max() ?? -1) + 1
        let entry = SessionExercise(order: order, exercise: exercise)
        session.entries.append(entry)
        try save()
        return entry
    }

    /// Removes an exercise (and its sets) from the session and returns a snapshot for undo.
    @discardableResult
    func remove(_ entry: SessionExercise, from session: WorkoutSession) throws -> EntrySnapshot {
        let snapshot = EntrySnapshot(
            id: entry.id,
            order: entry.order,
            exerciseID: entry.exercise?.id,
            sets: entry.orderedSets.map(Self.snapshot)
        )
        session.entries.removeAll { $0.id == entry.id }
        context.delete(entry)
        renumber(session)
        try save()
        return snapshot
    }

    func restore(_ snapshot: EntrySnapshot, into session: WorkoutSession) throws {
        let exercise = snapshot.exerciseID.flatMap(exercise(withID:))
        let entry = SessionExercise(id: snapshot.id, order: snapshot.order, exercise: exercise)
        for entryToShift in session.entries where entryToShift.order >= snapshot.order {
            entryToShift.order += 1
        }
        session.entries.append(entry)
        for set in snapshot.sets {
            entry.sets.append(Self.makeSet(from: set))
        }
        renumber(session)
        try save()
    }

    // MARK: Sets

    @discardableResult
    func addSet(_ values: SetValues, to entry: SessionExercise, at date: Date = .now) throws -> WorkoutSet {
        let order = (entry.sets.map(\.order).max() ?? -1) + 1
        let set = WorkoutSet(order: order, weight: values.weight, reps: values.reps,
                             rir: values.rir, type: values.type, loggedAt: date)
        entry.sets.append(set)
        try save()
        return set
    }

    /// Updates a set's values and returns the previous values for undo.
    @discardableResult
    func update(_ set: WorkoutSet, to values: SetValues) throws -> SetValues {
        let previous = set.values
        set.values = values
        try save()
        return previous
    }

    /// Deletes a set, renumbers the rest, and returns a snapshot for undo.
    @discardableResult
    func delete(_ set: WorkoutSet, from entry: SessionExercise) throws -> SetSnapshot {
        let snapshot = Self.snapshot(set)
        entry.sets.removeAll { $0.id == set.id }
        context.delete(set)
        renumber(entry)
        try save()
        return snapshot
    }

    func restore(_ snapshot: SetSnapshot, into entry: SessionExercise) throws {
        for other in entry.sets where other.order >= snapshot.order {
            other.order += 1
        }
        entry.sets.append(Self.makeSet(from: snapshot))
        renumber(entry)
        try save()
    }

    // MARK: History lookup

    /// Sets (in order) of this exercise from the most recent *other* session that started
    /// before `session` and has at least one set for it.
    static func lastSessionSets(for exercise: Exercise, before session: WorkoutSession) -> [SetValues] {
        let candidates = exercise.sessionEntries.compactMap { entry -> (Date, SessionExercise)? in
            guard let other = entry.session, other.id != session.id,
                  other.startedAt < session.startedAt, !entry.sets.isEmpty else { return nil }
            return (other.startedAt, entry)
        }
        guard let latest = candidates.max(by: { $0.0 < $1.0 })?.1 else { return [] }
        return latest.orderedSets.map(\.values)
    }

    // MARK: Helpers

    func exercise(withID id: UUID) -> Exercise? {
        var descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func renumber(_ entry: SessionExercise) {
        for (index, set) in entry.orderedSets.enumerated() {
            set.order = index
        }
    }

    private func renumber(_ session: WorkoutSession) {
        for (index, entry) in session.orderedEntries.enumerated() {
            entry.order = index
        }
    }

    private static func snapshot(_ set: WorkoutSet) -> SetSnapshot {
        SetSnapshot(id: set.id, order: set.order, values: set.values, loggedAt: set.loggedAt)
    }

    private static func makeSet(from snapshot: SetSnapshot) -> WorkoutSet {
        WorkoutSet(id: snapshot.id, order: snapshot.order, weight: snapshot.values.weight,
                   reps: snapshot.values.reps, rir: snapshot.values.rir,
                   type: snapshot.values.type, loggedAt: snapshot.loggedAt)
    }
}
