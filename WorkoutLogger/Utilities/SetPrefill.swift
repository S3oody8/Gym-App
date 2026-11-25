import Foundation

/// What the set pad starts with when adding a set (SPEC §3 Prefill).
struct SetPrefill: Equatable, Sendable {
    var weight: Double?
    /// Grey hint shown in an empty Reps field (not filled in).
    var repsHint: Int?
    /// Where the cursor starts.
    var field: SetEntryField
}
