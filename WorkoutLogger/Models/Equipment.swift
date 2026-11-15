import Foundation

/// Equipment tag for an exercise. Stored on `Exercise` as its raw `String` value.
enum Equipment: String, CaseIterable, Codable, Identifiable, Sendable {
    case smith = "Smith"
    case machine = "Machine"
    case cable = "Cable"
    case dumbbell = "Dumbbell"
    case barbell = "Barbell"
    case bodyweight = "Bodyweight"

    var id: String { rawValue }
}
