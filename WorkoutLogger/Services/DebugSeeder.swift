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
        case .workoutMid, .workoutPopup, .workoutRemoveUndo:
            let start = Date.now.addingTimeInterval(-25 * 60)
            let current = WorkoutSession(startedAt: start)
            context.insert(current)
            add([(82.5, 8), (82.5, 7)], of: bench, order: 0, to: current, start: start)
            add([(65, 10)], of: pulldown, order: 1, to: current, start: start.addingTimeInterval(900))
        case .exercises, .exerciseEditor:
            break
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
