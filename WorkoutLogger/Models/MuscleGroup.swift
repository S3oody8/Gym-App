import Foundation

/// Fixed list of muscle groups. Stored on `Exercise` as raw `String` values.
/// Raw values are persisted — never change them.
enum MuscleGroup: String, CaseIterable, Codable, Identifiable, Sendable {
    case chest = "Chest"
    case lats = "Lats"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case traps = "Traps"
    case frontDelts = "Front Delts"
    case sideDelts = "Side Delts"
    case rearDelts = "Rear Delts"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case adductors = "Adductors"
    case calves = "Calves"

    var id: String { rawValue }
}
