import Foundation

/// Pure planning for the Shrug import.
///
/// - Rows are grouped into workouts by "Workout Start"; exercises keep their order of first
///   appearance; sets keep file order.
/// - Timed rows (Reps/Secs = secs) are skipped and counted per exercise.
/// - lb rows are converted (× 0.45359237, rounded to 0.1 kg) unless the exercise is marked
///   "already kg".
/// - Ids are derived from (Workout Start, Shrug exercise name, set order), so a re-import maps
///   onto the same records and adds nothing.
enum ShrugImportPlanner {
    static let poundsToKg = 0.45359237

    static func exerciseInfo(_ rows: [ShrugRow]) -> [ShrugExerciseInfo] {
        var order: [String] = []
        var info: [String: ShrugExerciseInfo] = [:]
        for row in rows {
            if info[row.exercise] == nil {
                order.append(row.exercise)
                info[row.exercise] = ShrugExerciseInfo(name: row.exercise, rowCount: 0, poundRows: 0, timedRows: 0)
            }
            info[row.exercise]!.rowCount += 1
            if row.isTimed { info[row.exercise]!.timedRows += 1; continue }
            if row.isPounds {
                info[row.exercise]!.poundRows += 1
                if info[row.exercise]!.poundExample == nil { info[row.exercise]!.poundExample = row.weight }
            }
        }
        return order.map { info[$0]! }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func kilograms(fromPounds lb: Double) -> Double {
        (lb * poundsToKg * 10).rounded() / 10
    }

    /// Final exercise name for a Shrug name, following renames and merges (cycle-safe).
    static func targetName(for source: String, mappings: [String: ShrugMapping]) -> String {
        var current = source
        var seen: Set<String> = []
        while !seen.contains(current) {
            seen.insert(current)
            switch mappings[current] ?? .keep {
            case .keep:
                return current
            case .rename(let name):
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? current : trimmed
            case .merge(let into):
                current = into
            }
        }
        return current
    }

    static func plan(rows: [ShrugRow], mappings: [String: ShrugMapping],
                     alreadyKg: Set<String>) -> ShrugPlan {
        var workoutOrder: [String] = []
        var grouped: [String: [ShrugRow]] = [:]
        var skippedTimed: [String: Int] = [:]
        for row in rows {
            if row.isTimed { skippedTimed[row.exercise, default: 0] += 1; continue }
            if grouped[row.startText] == nil { workoutOrder.append(row.startText) }
            grouped[row.startText, default: []].append(row)
        }

        var exerciseNames: [String] = []
        var seenTargets: Set<String> = []
        var workouts: [ShrugPlan.Workout] = []
        for key in workoutOrder {
            let rowsInWorkout = grouped[key]!
            var entryOrder: [String] = []
            var setsBySource: [String: [ShrugRow]] = [:]
            for row in rowsInWorkout {
                if setsBySource[row.exercise] == nil { entryOrder.append(row.exercise) }
                setsBySource[row.exercise, default: []].append(row)
            }
            let entries = entryOrder.enumerated().map { index, source -> ShrugPlan.Entry in
                let target = targetName(for: source, mappings: mappings)
                if seenTargets.insert(ExerciseDraft.nameKey(target)).inserted { exerciseNames.append(target) }
                let sets = setsBySource[source]!.enumerated().map { setIndex, row in
                    ShrugPlan.PlannedSet(
                        id: StableID.uuid("shrug|set|\(key)|\(source)|\(setIndex)"),
                        order: setIndex,
                        weight: row.isPounds && !alreadyKg.contains(source) ? kilograms(fromPounds: row.weight) : row.weight,
                        reps: row.reps
                    )
                }
                return ShrugPlan.Entry(id: StableID.uuid("shrug|entry|\(key)|\(source)"), order: index,
                                       exerciseName: target, sets: sets)
            }
            workouts.append(ShrugPlan.Workout(id: StableID.uuid("shrug|workout|\(key)"),
                                              start: rowsInWorkout[0].start, entries: entries))
        }
        return ShrugPlan(workouts: workouts, exerciseNames: exerciseNames, skippedTimed: skippedTimed)
    }
}
