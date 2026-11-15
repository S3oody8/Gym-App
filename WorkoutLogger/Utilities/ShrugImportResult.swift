import Foundation

/// Summary shown after a Shrug import.
struct ShrugImportResult: Equatable, Sendable {
    var workoutsAdded = 0
    var setsAdded = 0
    var exercisesCreated = 0
    /// Sets already present from an earlier import (matched by Workout Start + exercise + set order).
    var setsAlreadyImported = 0
    var skippedTimed: [String: Int] = [:]
    var unreadableLines = 0

    var skippedTimedTotal: Int { skippedTimed.values.reduce(0, +) }
}
