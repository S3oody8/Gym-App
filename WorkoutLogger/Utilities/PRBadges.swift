import Foundation

/// PR badges a set can earn.
struct PRBadges: OptionSet, Hashable, Sendable {
    let rawValue: Int
    /// Heaviest weight ever for the exercise.
    static let weight = PRBadges(rawValue: 1 << 0)
    /// Most reps at this weight (beats every earlier set at ≥ this weight).
    static let reps = PRBadges(rawValue: 1 << 1)
}
