import Foundation
import SwiftData

/// Fills an in-memory store with sample data for a `DebugScenario` (Debug builds only).
@MainActor
enum DebugSeeder {
    static func seed(_ scenario: DebugScenario, into context: ModelContext) {
        #if DEBUG
        let bench = Exercise(name: "Bench Press", primary: .chest, secondary: [.frontDelts, .triceps],
                             equipment: .barbell, weightIncrement: 2.5)
        let pulldown = Exercise(name: "Lat Pulldown – Neutral", primary: .lats, secondary: [.biceps],
                                equipment: .cable, weightIncrement: 5)
        let curl = Exercise(name: "Incline DB Curl", primary: .biceps, equipment: .dumbbell,
                            weightIncrement: 2)
        let smith = Exercise(name: "Smith Squat", primary: .quads, secondary: [.glutes],
                             equipment: .smith, weightIncrement: 5)
        let oldRow = Exercise(name: "T-Bar Row", primary: .upperBack, equipment: .machine,
                              weightIncrement: 5, isArchived: true)
        [bench, pulldown, curl, smith, oldRow].forEach(context.insert)

        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        let past = WorkoutSession(startedAt: lastWeek, finishedAt: lastWeek.addingTimeInterval(3600))
        context.insert(past)
        add([(80, 8), (80, 7), (80, 6)], of: bench, order: 0, to: past, start: lastWeek)
        add([(65, 10), (65, 9)], of: pulldown, order: 1, to: past, start: lastWeek)
        add([(60, 6)], of: oldRow, order: 2, to: past, start: lastWeek)

        switch scenario {
        case .workoutEmpty, .workoutDiscard:
            context.insert(WorkoutSession(startedAt: .now.addingTimeInterval(-120)))
        case .workoutMid, .workoutPopup, .workoutRemoveUndo, .restAlert, .settings:
            let start = Date.now.addingTimeInterval(-25 * 60)
            let current = WorkoutSession(startedAt: start)
            context.insert(current)
            add([(82.5, 8), (82.5, 7)], of: bench, order: 0, to: current, start: start)
            add([(65, 10)], of: pulldown, order: 1, to: current, start: start.addingTimeInterval(900))
        case .exercises, .exerciseEditor:
            break
        case .history, .historyDetail, .historyDeleteFromDetail, .templatePicker:
            let day = 86_400.0
            let older = WorkoutSession(startedAt: lastWeek.addingTimeInterval(-3 * day))
            context.insert(older)
            add([(100, 5), (100, 5), (100, 4)], of: smith, order: 0, to: older,
                start: older.startedAt.addingTimeInterval(300))
            add([(14, 12), (14, 10)], of: curl, order: 1, to: older,
                start: older.startedAt.addingTimeInterval(1500))
            older.finishedAt = older.startedAt.addingTimeInterval(2700)
            let recent = WorkoutSession(startedAt: Date.now.addingTimeInterval(-2 * day))
            context.insert(recent)
            add([(82.5, 8), (82.5, 7), (82.5, 6)], of: bench, order: 0, to: recent,
                start: recent.startedAt.addingTimeInterval(240))
            add([(70, 10), (70, 9)], of: pulldown, order: 1, to: recent,
                start: recent.startedAt.addingTimeInterval(1500))
            recent.entries.first?.sets.last?.type = .drop
            recent.finishedAt = recent.startedAt.addingTimeInterval(3600)
            let push = WorkoutTemplate(name: "Upper A")
            context.insert(push)
            for (i, ex) in [bench, pulldown, curl].enumerated() {
                push.items.append(TemplateExercise(order: i, exercise: ex))
            }
            let legs = WorkoutTemplate(name: "Lower A")
            context.insert(legs)
            legs.items.append(TemplateExercise(order: 0, exercise: smith))
        }
        try? context.save()
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
