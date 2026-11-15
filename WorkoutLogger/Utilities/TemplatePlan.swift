import Foundation

/// Pure rules for templates: which exercises a session contributes, in order.
enum TemplatePlan {
    /// Exercise ids in performed order, skipping entries whose exercise was deleted.
    /// Repeats are kept (an exercise done twice appears twice).
    static func exerciseIDs(from entries: [(order: Int, exerciseID: UUID?)]) -> [UUID] {
        entries.sorted { $0.order < $1.order }.compactMap(\.exerciseID)
    }
}
