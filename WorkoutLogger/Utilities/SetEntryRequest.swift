import Foundation

/// Opens the set pop-up: either adding a new set to an entry or editing an existing set.
struct SetEntryRequest: Identifiable, Equatable, Sendable {
    let id = UUID()
    let entryID: UUID
    /// Set being edited, or nil when adding.
    let setID: UUID?
    let exerciseName: String
    let initial: SetValues?
    let increment: Double

    var isEditing: Bool { setID != nil }
}
