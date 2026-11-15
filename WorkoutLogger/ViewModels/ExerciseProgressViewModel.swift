import Foundation
import Observation

/// Per-exercise progress: graph metric/range and the full set history with PR badges.
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

    var badges: [UUID: PRBadges] {
        PRDetector.badges(for: ProgressQueries.prInputs(for: exercise))
    }

    var history: [(session: WorkoutSession, sets: [WorkoutSet])] {
        ProgressQueries.sessionGroups(for: exercise)
    }
}
