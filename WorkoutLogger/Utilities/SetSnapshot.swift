import Foundation

/// Everything needed to re-create a deleted set (same id) for undo.
struct SetSnapshot: Equatable, Sendable {
    var id: UUID
    var order: Int
    var values: SetValues
    var loggedAt: Date
}
