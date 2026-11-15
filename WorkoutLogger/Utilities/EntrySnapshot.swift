import Foundation

/// Everything needed to re-create a removed session exercise (same id, same sets) for undo.
struct EntrySnapshot: Equatable, Sendable {
    var id: UUID
    var order: Int
    var exerciseID: UUID?
    var sets: [SetSnapshot]
}
