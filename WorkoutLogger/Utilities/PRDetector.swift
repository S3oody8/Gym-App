import Foundation

/// Pure PR detection over one exercise's whole history. Working sets only.
///
/// Sets are taken in chronological order (session start, then set order). Each set is compared
/// with every *earlier* working set (earlier sessions and earlier sets in the same session):
/// - Weight PR: weight is strictly greater than every earlier set's weight.
/// - Reps PR: there is at least one earlier set at ≥ this weight, and reps are strictly greater
///   than every earlier set at ≥ this weight.
/// Sets in the exercise's first session never get badges (nothing to beat yet).
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
        var earlier: [SetValues] = []
        for set in ordered {
            defer { earlier.append(set.values) }
            guard set.sessionID != firstSession, !earlier.isEmpty else { continue }
            var badges: PRBadges = []
            let w = set.values.weight
            if let maxWeight = earlier.map(\.weight).max(), w > maxWeight {
                badges.insert(.weight)
            }
            let atOrAbove = earlier.filter { $0.weight >= w }
            if let maxReps = atOrAbove.map(\.reps).max(), set.values.reps > maxReps {
                badges.insert(.reps)
            }
            if !badges.isEmpty { result[set.id] = badges }
        }
        return result
    }
}
