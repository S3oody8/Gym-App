import Foundation
import SwiftData

/// Writes a `ShrugPlan` into the store in batches, reporting progress between batches so the
/// UI stays responsive. Anything whose id already exists is skipped (never overwritten), so
/// running it again — or after an interruption — only adds what's missing.
@MainActor
struct ShrugImporter {
    let context: ModelContext
    var batchSize = 500
    /// Debug-only pause between batches (to screenshot the progress bar).
    var batchDelay: Duration = .zero

    func run(_ plan: ShrugPlan, unreadableLines: Int = 0,
             progress: (Int, Int) -> Void = { _, _ in }) async throws -> ShrugImportResult {
        var result = ShrugImportResult(skippedTimed: plan.skippedTimed, unreadableLines: unreadableLines)

        // Exercises by target name (existing ones are reused, matched trimmed + case-insensitive).
        var byName: [String: Exercise] = [:]
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) {
            byName[ExerciseDraft.nameKey(exercise.name)] = byName[ExerciseDraft.nameKey(exercise.name)] ?? exercise
        }
        for name in plan.exerciseNames where byName[ExerciseDraft.nameKey(name)] == nil {
            let exercise = Exercise(name: name, equipment: .machine)
            context.insert(exercise)
            byName[ExerciseDraft.nameKey(name)] = exercise
            result.exercisesCreated += 1
        }
        try context.save()

        var sessions = Dictionary(try context.fetch(FetchDescriptor<WorkoutSession>()).map { ($0.id, $0) },
                                  uniquingKeysWith: { a, _ in a })
        var entries = Dictionary(try context.fetch(FetchDescriptor<SessionExercise>()).map { ($0.id, $0) },
                                 uniquingKeysWith: { a, _ in a })
        let existingSets = Set(try context.fetch(FetchDescriptor<WorkoutSet>()).map(\.id))

        let total = plan.setCount
        var done = 0
        var sinceSave = 0
        progress(0, total)
        for workout in plan.workouts {
            let session: WorkoutSession
            if let existing = sessions[workout.id] {
                session = existing
            } else {
                session = WorkoutSession(id: workout.id, startedAt: workout.start, finishedAt: workout.start)
                context.insert(session)
                sessions[workout.id] = session
                result.workoutsAdded += 1
            }
            for planned in workout.entries {
                let entry: SessionExercise
                if let existing = entries[planned.id] {
                    entry = existing
                } else {
                    entry = SessionExercise(id: planned.id, order: planned.order,
                                            exercise: byName[ExerciseDraft.nameKey(planned.exerciseName)])
                    session.entries.append(entry)
                    entries[planned.id] = entry
                }
                for set in planned.sets {
                    done += 1
                    if existingSets.contains(set.id) {
                        result.setsAlreadyImported += 1
                        continue
                    }
                    entry.sets.append(WorkoutSet(id: set.id, order: set.order, weight: set.weight,
                                                 reps: set.reps, rir: nil, type: .working, loggedAt: workout.start))
                    result.setsAdded += 1
                    sinceSave += 1
                    if sinceSave >= batchSize {
                        try context.save()
                        sinceSave = 0
                        progress(done, total)
                        if batchDelay > .zero { try? await Task.sleep(for: batchDelay) }
                        await Task.yield()
                    }
                }
            }
        }
        try context.save()
        progress(total, total)
        return result
    }
}
