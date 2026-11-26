import Foundation

/// Pure PR detection over one exercise's whole history. Working sets only.
///
/// Sets are taken in chronological order (session start, then set order). Each set is compared
/// with every *earlier* working set (earlier sessions and earlier sets in the same session):
/// - Weight PR: weight is strictly greater than every earlier set's weight.
/// - Reps PR: there is at least one earlier set at ≥ this weight, and reps are strictly greater
///   than every earlier set at ≥ this weight.
/// Sets in the exercise's first session never get badges (nothing to beat yet).
///
/// One pass with running state: the heaviest weight so far and the best reps at each distinct
/// weight. The reps check only looks at weights ≥ this one, and an exercise has few distinct
/// weights, so this is close to O(n) (it was O(n²)).
enum PRDetector {
    static func badges(for sets: [PRInputSet]) -> [UUID: PRBadges] {
        let ordered = sets
            .filter { $0.values.type == .working }
            .sorted {
                if $0.sessionStart != $1.sessionStart { return $0.sessionStart < $1.sessionStart }
                if $0.sessionID != $1.sessionID { return $0.sessionID.uuidString < $1.sessionID.uuidString }
                return $0.order < $1.order
            }
        guard let firstSession = ordered.first?.sessionID else { return [:] }

        var result: [UUID: PRBadges] = [:]
        var maxWeight = -Double.infinity
        var maxRepsByWeight: [Double: Int] = [:]
        for set in ordered {
            let w = set.values.weight
            let reps = set.values.reps
            if set.sessionID != firstSession {
                var badges: PRBadges = []
                if w > maxWeight { badges.insert(.weight) }
                var bestReps: Int?
                for (weight, r) in maxRepsByWeight where weight >= w {
                    bestReps = max(bestReps ?? r, r)
                }
                if let bestReps, reps > bestReps { badges.insert(.reps) }
                if !badges.isEmpty { result[set.id] = badges }
            }
            // Update the running state after the comparison.
            maxWeight = max(maxWeight, w)
            maxRepsByWeight[w] = max(maxRepsByWeight[w] ?? reps, reps)
        }
        return result
    }
}
