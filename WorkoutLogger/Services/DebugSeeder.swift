import Foundation
import SwiftData

/// Fills an in-memory store with sample data for a `DebugScenario` (Debug builds only).
@MainActor
enum DebugSeeder {
    static func seed(_ scenario: DebugScenario, into context: ModelContext) {
        #if DEBUG
        if [.shrugMapping, .shrugProgress, .shrugSummary, .shrugHistory].contains(scenario) { return }
        if scenario == .largeHistory {
            seedLargeHistory(into: context)
            PRCache.shared(for: context).invalidateAll()
            return
        }
        let bench = Exercise(name: "Bench Press", equipment: .barbell, weightIncrement: 2.5)
        let pulldown = Exercise(name: "Lat Pulldown – Neutral", equipment: .cable, weightIncrement: 5)
        let curl = Exercise(name: "Incline DB Curl", equipment: .dumbbell,
                            weightIncrement: 2)
        let smith = Exercise(name: "Smith Squat", equipment: .smith, weightIncrement: 5)
        let oldRow = Exercise(name: "T-Bar Row", equipment: .machine,
                              weightIncrement: 5, isArchived: true)
        [bench, pulldown, curl, smith, oldRow].forEach(context.insert)

        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let past = WorkoutSession(name: "Anterior", startedAt: lastWeek, finishedAt: lastWeek.addingTimeInterval(3600))
        context.insert(past)
        add([(80, 8), (80, 7), (80, 6)], of: bench, order: 0, to: past, start: lastWeek)
        add([(65, 10), (65, 9)], of: pulldown, order: 1, to: past, start: lastWeek)
        add([(60, 6)], of: oldRow, order: 2, to: past, start: lastWeek)

        switch scenario {
        case .workoutEmpty, .workoutDiscard:
            context.insert(WorkoutSession(startedAt: .now.addingTimeInterval(-120)))
        case .workoutMid, .workoutPopup, .workoutRemoveUndo, .restAlert, .settings:
            let start = Date.now.addingTimeInterval(-25 * 60)
            let current = WorkoutSession(name: "Anterior", startedAt: start)
            context.insert(current)
            add([(82.5, 8), (82.5, 7), (82.5, 6)], of: bench, order: 0, to: current, start: start)
            current.entries.first?.sets.append(WorkoutSet(order: 3, weight: 60, reps: 10, type: .drop,
                                                          loggedAt: start.addingTimeInterval(600)))
            add([(65, 11), (65, 9)], of: pulldown, order: 1, to: current, start: start.addingTimeInterval(900))
        case .exercises, .exerciseEditor, .shrugMapping, .shrugProgress, .shrugSummary, .shrugHistory, .largeHistory:
            break
        case .progress, .exerciseProgress:
            let day = 86_400.0
            for i in 0..<16 {
                let date = Date.now.addingTimeInterval(-Double(100 - i * 6) * day - 3600)
                let anterior = i % 2 == 0
                let session = WorkoutSession(name: anterior ? "Anterior" : "Posterior", startedAt: date)
                context.insert(session)
                let step = Double(i / 2)
                if anterior {
                    let w = 70 + (step * 1.25 / 2.5).rounded() * 2.5
                    add([(w, 8 + i % 3), (w, 7 + i % 2), (w - 10, 10)], of: bench, order: 0, to: session,
                        start: date.addingTimeInterval(300))
                    add([(55 + step * 2.5, 10), (55 + step * 2.5, 9)], of: pulldown, order: 1,
                        to: session, start: date.addingTimeInterval(1500))
                } else {
                    add([(90 + step * 5, 6), (90 + step * 5, 5)], of: smith, order: 0, to: session,
                        start: date.addingTimeInterval(300))
                    add([(12 + step, 12), (12 + step, 10)], of: curl, order: 1, to: session,
                        start: date.addingTimeInterval(1500))
                }
                session.finishedAt = date.addingTimeInterval(3000)
            }
        case .history, .historyDetail, .historyDeleteFromDetail, .templatePicker:
            let day = 86_400.0
            let older = WorkoutSession(name: "Posterior", startedAt: lastWeek.addingTimeInterval(-3 * day))
            context.insert(older)
            add([(100, 5), (100, 5), (100, 4)], of: smith, order: 0, to: older,
                start: older.startedAt.addingTimeInterval(300))
            add([(14, 12), (14, 10)], of: curl, order: 1, to: older,
                start: older.startedAt.addingTimeInterval(1500))
            older.finishedAt = older.startedAt.addingTimeInterval(2700)
            let recent = WorkoutSession(name: "Anterior", startedAt: Date.now.addingTimeInterval(-2 * day))
            context.insert(recent)
            add([(82.5, 8), (82.5, 7), (82.5, 6)], of: bench, order: 0, to: recent,
                start: recent.startedAt.addingTimeInterval(240))
            add([(70, 10), (70, 9)], of: pulldown, order: 1, to: recent,
                start: recent.startedAt.addingTimeInterval(1500))
            recent.entries.first?.sets.last?.type = .drop
            recent.finishedAt = recent.startedAt.addingTimeInterval(3600)
            let push = WorkoutTemplate(name: "Anterior")
            context.insert(push)
            for (i, ex) in [bench, pulldown, curl].enumerated() {
                push.items.append(TemplateExercise(order: i, exercise: ex))
            }
            let legs = WorkoutTemplate(name: "Posterior")
            context.insert(legs)
            legs.items.append(TemplateExercise(order: 0, exercise: smith))
        }
        try? context.save()
        PRCache.shared(for: context).invalidateAll()
        #endif
    }

    /// About the size of the user's real history: 300 finished workouts over two years,
    /// 15 exercises, 4 exercises × 5 sets per workout (6,000 sets). Deterministic, so timings
    /// are comparable between runs. Used by the `largeHistory` scenario and the perf tests.
    static func seedLargeHistory(into context: ModelContext, sessions sessionCount: Int = 300,
                                 now: Date = Date(timeIntervalSince1970: 1_795_000_000)) {
        let names = ["Bench Press", "Incline DB Press", "Chest Fly", "Shoulder Press", "Lateral Raise",
                     "Lat Pulldown", "Seated Row", "T-Bar Row", "Rear Delt Fly", "Curl",
                     "Smith Squat", "Leg Press", "Romanian Deadlift", "Leg Curl", "Calf Raise"]
        let exercises = names.map { Exercise(name: $0, equipment: .machine, weightIncrement: 2.5) }
        exercises.forEach(context.insert)
        var seed: UInt64 = 42
        func random(_ range: Int) -> Int {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((seed >> 33) % UInt64(range))
        }
        let span = 730.0 * 86_400
        for i in 0..<sessionCount {
            let start = now.addingTimeInterval(-span + span * Double(i) / Double(sessionCount))
            let session = WorkoutSession(name: ["Push", "Pull", "Legs"][i % 3], startedAt: start)
            context.insert(session)
            let split = (i % 3) * 5
            let progress = Double(i) / Double(sessionCount)
            for slot in 0..<4 {
                let exercise = exercises[split + (slot + i / 3) % 5]
                let base = 20 + Double(split + slot) * 4
                let weight = ((base + base * progress + Double(random(5))) / 2.5).rounded() * 2.5
                let entry = SessionExercise(order: slot, exercise: exercise)
                session.entries.append(entry)
                for index in 0..<5 {
                    let isDrop = index == 4 && random(3) == 0
                    entry.sets.append(WorkoutSet(
                        order: index, weight: isDrop ? weight - 10 : weight - Double(index / 2) * 2.5,
                        reps: 6 + random(7), rir: random(3), type: isDrop ? .drop : .working,
                        loggedAt: start.addingTimeInterval(Double(slot * 5 + index) * 150)))
                }
            }
            session.finishedAt = start.addingTimeInterval(20 * 150)
        }
        try? context.save()
    }

    /// Runs a default Shrug import (convert lb, keep names) from `-shrugFile`, for screenshots.
    static func importShrugIfNeeded(into context: ModelContext) async {
        #if DEBUG
        guard DebugScenario.current == .shrugHistory, let text = DebugScenario.shrugFileText,
              let parsed = try? ShrugCSVParser.parse(text) else { return }
        let plan = ShrugImportPlanner.plan(rows: parsed.rows, mappings: [:], alreadyKg: [])
        _ = try? await ShrugImporter(context: context).run(plan)
        #endif
    }

    private static func add(_ sets: [(Double, Int)], of exercise: Exercise, order: Int,
                            to session: WorkoutSession, start: Date) {
        let entry = SessionExercise(order: order, exercise: exercise)
        session.entries.append(entry)
        for (index, set) in sets.enumerated() {
            entry.sets.append(WorkoutSet(order: index, weight: set.0, reps: set.1,
                                         rir: index == sets.count - 1 ? 0 : nil,
                                         loggedAt: start.addingTimeInterval(Double(index) * 180)))
        }
    }
}
