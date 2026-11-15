import Foundation

/// Time range for the per-exercise graph.
enum ProgressRange: String, CaseIterable, Identifiable, Sendable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String { rawValue }

    /// Earliest date included, or nil for All.
    func startDate(now: Date, calendar: Calendar = .current) -> Date? {
        let months: Int
        switch self {
        case .oneMonth: months = 1
        case .threeMonths: months = 3
        case .sixMonths: months = 6
        case .oneYear: months = 12
        case .all: return nil
        }
        return calendar.date(byAdding: .month, value: -months, to: now)
    }
}
