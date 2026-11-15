import Foundation

/// Type of a logged set. Stored on `WorkoutSet` as its raw `String` value.
enum SetType: String, CaseIterable, Codable, Identifiable, Sendable {
    case working = "Working"
    case drop = "Drop"

    var id: String { rawValue }
}
