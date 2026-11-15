import Foundation

/// Pure rules for quick-add sets, pre-fill, "Last:" matching and weight stepping.
enum SetPlanner {
    /// −1/−2/−3 buttons: same weight as `previous`, reps reduced by `minus` (minimum 1).
    static func quickSet(from previous: SetValues, minus: Int) -> SetValues {
        SetValues(weight: previous.weight, reps: max(1, previous.reps - minus), rir: nil, type: .working)
    }

    /// "+ Set" pre-fill: last set of this exercise in this session, otherwise the last set
    /// in history. Only weight and reps are carried over.
    static func prefill(sessionSets: [SetValues], historySets: [SetValues]) -> SetValues? {
        guard let source = sessionSets.last ?? historySets.last else { return nil }
        return SetValues(weight: source.weight, reps: source.reps, rir: nil, type: .working)
    }

    /// Set at the same position in the previous session, if it had that many sets.
    static func matchingLast(index: Int, in lastSession: [SetValues]) -> SetValues? {
        lastSession.indices.contains(index) ? lastSession[index] : nil
    }

    /// Weight ± button. Never goes below 0; rounded to 0.01 kg to avoid float noise.
    static func step(weight: Double, by increment: Double, up: Bool) -> Double {
        let next = up ? weight + increment : weight - increment
        return max(0, (next * 100).rounded() / 100)
    }
}
