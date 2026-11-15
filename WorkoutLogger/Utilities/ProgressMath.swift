import Foundation

/// Pure progress maths: e1RM, per-session metric values, range filtering.
enum ProgressMath {
    static let maxE1RMReps = 12

    /// Epley: w × (1 + reps/30) for 2…12 reps; reps == 1 → w; otherwise nil.
    static func e1RM(weight: Double, reps: Int) -> Double? {
        guard reps >= 1, reps <= maxE1RMReps else { return nil }
        return reps == 1 ? weight : weight * (1 + Double(reps) / 30)
    }

    /// The session's value for `metric`, or nil if no set qualifies.
    /// e1RM and top set use Working sets only; volume uses Working + Drop.
    static func value(_ metric: ProgressMetric, sets: [SetValues]) -> Double? {
        let working = sets.filter { $0.type == .working }
        switch metric {
        case .e1RM:
            return working.compactMap { e1RM(weight: $0.weight, reps: $0.reps) }.max()
        case .topSet:
            return working.map(\.weight).max()
        case .volume:
            let counted = sets.filter { $0.type == .working || $0.type == .drop }
            guard !counted.isEmpty else { return nil }
            return SessionMetrics.load(counted)
        }
    }

    /// One point per session (oldest first), limited to `range`.
    static func points(
        _ metric: ProgressMetric,
        sessions: [ProgressSessionInput],
        range: ProgressRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [ProgressPoint] {
        let start = range.startDate(now: now, calendar: calendar)
        return sessions
            .filter { start == nil || $0.date >= start! }
            .compactMap { session in
                value(metric, sets: session.sets).map { ProgressPoint(date: session.date, value: $0) }
            }
            .sorted { $0.date < $1.date }
    }

    /// "102.3 kg" style label (1 decimal max for e1RM, whole kg for volume).
    static func label(_ value: Double, metric: ProgressMetric) -> String {
        switch metric {
        case .volume:
            return SessionMetrics.loadText(value).replacingOccurrences(of: "Load ", with: "")
        case .e1RM:
            return "\(value.formatted(.number.precision(.fractionLength(0...1)).grouping(.never).locale(Locale(identifier: "en_US_POSIX")))) kg"
        case .topSet:
            return "\(WeightFormatter.string(value)) kg"
        }
    }
}
