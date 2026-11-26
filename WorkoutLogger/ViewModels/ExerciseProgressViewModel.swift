import Foundation
import Observation

/// Per-exercise progress: graph metric/range and the full set history (badges come from `PRCache`).
@MainActor
@Observable
final class ExerciseProgressViewModel {
    let exercise: Exercise
    var metric: ProgressMetric
    var range: ProgressRange = .threeMonths

    init(exercise: Exercise, metric: ProgressMetric = .e1RM) {
        self.exercise = exercise
        self.metric = metric
    }

    func points(now: Date = .now) -> [ProgressPoint] {
        ProgressMath.points(metric, sessions: ProgressQueries.sessionInputs(for: exercise),
                            range: range, now: now)
    }

    var history: [(session: WorkoutSession, sets: [WorkoutSet])] {
        ProgressQueries.sessionGroups(for: exercise)
    }
}
