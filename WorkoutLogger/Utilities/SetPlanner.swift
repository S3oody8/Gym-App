import Foundation

/// Pure rules for quick-add sets, the set pad prefill and ×2.
enum SetPlanner {
    /// Quick buttons: same weight as `previous`, reps reduced by `minus` (minimum 1).
    static func quickSet(from previous: SetValues, minus: Int) -> SetValues {
        SetValues(weight: previous.weight, reps: max(1, previous.reps - minus), rir: nil, type: .working)
    }

    /// Set pad prefill when adding a set:
    /// - later sets in this workout: the previous set's weight, reps empty, no hint;
    /// - first set in this workout: set 1 of the most recent earlier session's weight, with its
    ///   reps as a grey hint, cursor in Reps;
    /// - never done before: everything empty, cursor in Weight.
    static func prefill(sessionSets: [SetValues], previousSessionSets: [SetValues]) -> SetPrefill {
        if let previous = sessionSets.last {
            return SetPrefill(weight: previous.weight, repsHint: nil, field: .reps)
        }
        if let first = previousSessionSets.first {
            return SetPrefill(weight: first.weight, repsHint: first.reps, field: .reps)
        }
        return SetPrefill(weight: nil, repsHint: nil, field: .weight)
    }

    /// ×2: doubles a per-side weight into the total, rounded to 0.01 kg.
    static func doubled(_ weight: Double) -> Double {
        (weight * 2 * 100).rounded() / 100
    }
}
