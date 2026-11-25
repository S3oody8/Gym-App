import Foundation

/// Chart card numbers for one exercise, metric and range. Pure, no UI.
enum ProgressSummary {
    /// Latest value minus the first value in the range (nil with fewer than two points).
    static func change(_ points: [ProgressPoint]) -> Double? {
        guard points.count >= 2, let first = points.first, let last = points.last else { return nil }
        return last.value - first.value
    }

    /// "+4.5 kg" / "−120 kg" / "±0 kg".
    static func changeLabel(_ delta: Double, metric: ProgressMetric) -> String {
        let magnitude = ProgressMath.label(abs(delta), metric: metric)
        if abs(delta) < 0.05 { return "±\(ProgressMath.label(0, metric: metric))" }
        return (delta > 0 ? "+" : "−") + magnitude
    }

    /// The best working set in the range: highest e1RM (e1RM), heaviest then most reps
    /// (Top set), or highest weight × reps over working + drop sets (Volume).
    /// Ties go to the earlier set.
    static func bestSet(_ metric: ProgressMetric, sessions: [ProgressSessionInput], range: ProgressRange,
                        now: Date = .now, calendar: Calendar = .current) -> BestSet? {
        let start = range.startDate(now: now, calendar: calendar)
        let inRange = sessions
            .filter { session in start.map { session.date >= $0 } ?? true }
            .sorted { $0.date < $1.date }
        var candidates: [(date: Date, set: SetValues)] = []
        for session in inRange {
            for set in session.sets where counts(set, for: metric) {
                candidates.append((session.date, set))
            }
        }
        var best: (Date, SetValues, (Double, Double))?
        for (date, set) in candidates {
            let score: (Double, Double)
            switch metric {
            case .e1RM:
                guard let e = ProgressMath.e1RM(weight: set.weight, reps: set.reps) else { continue }
                score = (e, set.weight)
            case .topSet:
                score = (set.weight, Double(set.reps))
            case .volume:
                score = (set.weight * Double(set.reps), set.weight)
            }
            if best == nil || score > best!.2 { best = (date, set, score) }
        }
        return best.map { BestSet(values: $0.1, date: $0.0) }
    }

    /// Working sets count for e1RM and Top set; volume also counts drop sets.
    private static func counts(_ set: SetValues, for metric: ProgressMetric) -> Bool {
        set.type == .working || (metric == .volume && set.type == .drop)
    }

    /// RECENT PRs, newest first: every set with a PR badge, limited to `limit`.
    static func recentPRs(_ inputs: [(exerciseName: String, sets: [PRInputSet])], limit: Int = 10) -> [RecentPR] {
        inputs.flatMap { exercise -> [RecentPR] in
            let badges = PRDetector.badges(for: exercise.sets)
            return exercise.sets.compactMap { set in
                guard let badge = badges[set.id], !badge.isEmpty else { return nil }
                return RecentPR(id: set.id, exerciseName: exercise.exerciseName, date: set.sessionStart, values: set.values)
            }
        }
        .sorted { $0.date != $1.date ? $0.date > $1.date : $0.exerciseName < $1.exerciseName }
        .prefix(limit)
        .map { $0 }
    }
}
