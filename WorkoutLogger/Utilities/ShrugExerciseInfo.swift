import Foundation

/// Per-exercise facts shown on the mapping screen.
struct ShrugExerciseInfo: Equatable, Identifiable, Sendable {
    var name: String
    var rowCount: Int
    var poundRows: Int
    /// First lb weight seen, for the example on the mapping screen.
    var poundExample: Double?
    var timedRows: Int

    var id: String { name }
    var importableRows: Int { rowCount - timedRows }
}
