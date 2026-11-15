import Foundation

/// One session's sets for a single exercise, as plain values.
struct ProgressSessionInput: Equatable, Sendable {
    var date: Date
    var sets: [SetValues]
}
