import Foundation

/// One session's value for a metric.
struct ProgressPoint: Equatable, Identifiable, Sendable {
    var date: Date
    var value: Double
    var id: Date { date }
}
