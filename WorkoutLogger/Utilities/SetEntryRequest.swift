import Foundation

/// Opens the set pad: either adding a new set to an entry or editing an existing set.
struct SetEntryRequest: Identifiable, Equatable, Sendable {
    let id = UUID()
    let entryID: UUID
    /// Set being edited, or nil when adding.
    let setID: UUID?
    let exerciseName: String
    /// The set's values when editing.
    let initial: SetValues?
    /// What the pad starts with when adding (SPEC §3 Prefill).
    var prefill: SetPrefill?

    var isEditing: Bool { setID != nil }
}
