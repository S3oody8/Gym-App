import Foundation

/// Counts PR sets per session from PR badges computed over every exercise's history.
enum PRCounter {
    /// `setSessions` maps each set id to its session id. A set with any badge counts once.
    static func countsBySession(badges: [UUID: PRBadges], setSessions: [UUID: UUID]) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for (setID, badge) in badges where !badge.isEmpty {
            guard let sessionID = setSessions[setID] else { continue }
            counts[sessionID, default: 0] += 1
        }
        return counts
    }
}
