import Foundation

/// Plain values of a set, used for pre-fill, undo and comparisons.
struct SetValues: Equatable, Sendable {
    var weight: Double
    var reps: Int
    var rir: Int?
    var type: SetType = .working
}
