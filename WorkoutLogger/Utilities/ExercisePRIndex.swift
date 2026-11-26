import Foundation

/// Everything derived from one exercise's history that screens need repeatedly: PR badges,
/// PR sets per session, the PR sets themselves (for RECENT PRs) and the last-used date.
struct ExercisePRIndex: Sendable {
    var badges: [UUID: PRBadges]
    var prCountsBySession: [UUID: Int]
    /// PR sets as (set id, session start, values).
    var prSets: [(id: UUID, date: Date, values: SetValues)]
    /// Start of the most recent session with at least one set of the exercise.
    var lastUsed: Date?

    static let empty = ExercisePRIndex(badges: [:], prCountsBySession: [:], prSets: [], lastUsed: nil)

    init(badges: [UUID: PRBadges], prCountsBySession: [UUID: Int],
         prSets: [(id: UUID, date: Date, values: SetValues)], lastUsed: Date?) {
        self.badges = badges
        self.prCountsBySession = prCountsBySession
        self.prSets = prSets
        self.lastUsed = lastUsed
    }

    /// Builds the index from every set of the exercise (working and drop).
    init(sets: [PRInputSet]) {
        let badges = PRDetector.badges(for: sets)
        var counts: [UUID: Int] = [:]
        var prSets: [(id: UUID, date: Date, values: SetValues)] = []
        for set in sets {
            guard let badge = badges[set.id], !badge.isEmpty else { continue }
            counts[set.sessionID, default: 0] += 1
            prSets.append((set.id, set.sessionStart, set.values))
        }
        self.init(badges: badges, prCountsBySession: counts, prSets: prSets,
                  lastUsed: sets.map(\.sessionStart).max())
    }
}
