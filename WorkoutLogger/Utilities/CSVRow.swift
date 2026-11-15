import Foundation

/// One set in the CSV export.
struct CSVRow: Equatable, Sendable {
    var date: Date
    var session: String
    var exercise: String
    var setNumber: Int
    var type: SetType
    var weight: Double
    var reps: Int
    var rir: Int?
}
