import Foundation

/// A set of one exercise with enough context to order it chronologically.
struct PRInputSet: Equatable, Sendable {
    var id: UUID
    var sessionID: UUID
    var sessionStart: Date
    var order: Int
    var values: SetValues
}
