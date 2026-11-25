import Foundation

/// The best set behind a progress chart, e.g. "Best set 82.5 × 8 · Sat 22/11".
struct BestSet: Equatable, Sendable {
    var values: SetValues
    var date: Date
}
