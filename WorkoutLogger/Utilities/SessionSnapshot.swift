import Foundation

/// Everything needed to re-create a deleted session (same ids) for undo.
struct SessionSnapshot: Equatable, Sendable {
    var id: UUID
    var name: String = ""
    var startedAt: Date
    var finishedAt: Date?
    var entries: [EntrySnapshot]
}
