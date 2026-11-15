import Foundation

/// One data row of a Shrug CSV export
/// (`Workout Start, Exercise, Weight, Unit, Reps, Reps/Secs`).
struct ShrugRow: Equatable, Sendable {
    /// "2024-10-12 21:33" exactly as in the file (the workout key).
    var startText: String
    var start: Date
    /// Exercise name as cleaned for display (invisible characters removed, trimmed).
    var exercise: String
    var weight: Double
    var isPounds: Bool
    /// Reps, or seconds when `isTimed`.
    var reps: Int
    var isTimed: Bool
}
