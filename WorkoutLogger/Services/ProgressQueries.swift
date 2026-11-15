import Foundation

/// Reads one exercise's history from the model graph into plain values for the pure maths.
@MainActor
enum ProgressQueries {
    /// Every set of the exercise across all sessions, for PR detection.
    static func prInputs(for exercise: Exercise) -> [PRInputSet] {
        exercise.sessionEntries.flatMap { entry -> [PRInputSet] in
            guard let session = entry.session else { return [] }
            return entry.sets.map { set in
                // Order across repeated entries of the same exercise in one session.
                PRInputSet(id: set.id, sessionID: session.id, sessionStart: session.startedAt,
                           order: entry.order * 10_000 + set.order, values: set.values)
            }
        }
    }

    /// One input per session containing the exercise (sets of repeated entries merged).
    static func sessionInputs(for exercise: Exercise) -> [ProgressSessionInput] {
        sessionGroups(for: exercise).map { ProgressSessionInput(date: $0.session.startedAt, sets: $0.sets.map(\.values)) }
    }

    /// Sessions with this exercise's sets in order, newest first.
    static func sessionGroups(for exercise: Exercise) -> [(session: WorkoutSession, sets: [WorkoutSet])] {
        let entries = exercise.sessionEntries.filter { $0.session != nil && !$0.sets.isEmpty }
        let grouped = Dictionary(grouping: entries) { $0.session!.id }
        return grouped.values.compactMap { entries -> (WorkoutSession, [WorkoutSet])? in
            guard let session = entries.first?.session else { return nil }
            let sets = entries.sorted { $0.order < $1.order }.flatMap(\.orderedSets)
            return (session, sets)
        }
        .sorted { $0.0.startedAt > $1.0.startedAt }
    }
}
