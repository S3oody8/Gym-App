import Foundation

/// Pure month-grid maths for the training calendar. Weeks run Monday–Sunday.
enum CalendarMath {
    /// A Gregorian calendar with Monday as the first weekday, in `timeZone`.
    static func mondayCalendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = timeZone
        return calendar
    }

    /// Start of the month containing `date`.
    static func monthStart(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }

    /// Cells for a month grid: leading nils so day 1 lands in its weekday column (Monday first),
    /// then one start-of-day date per day of the month.
    static func monthGrid(for month: Date, calendar: Calendar) -> [Date?] {
        let start = monthStart(month, calendar: calendar)
        let days = calendar.range(of: .day, in: .month, for: start)!.count
        let weekday = calendar.component(.weekday, from: start) // 1 = Sunday … 7 = Saturday
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dates = (0..<days).map { calendar.date(byAdding: .day, value: $0, to: start)! }
        return Array(repeating: nil, count: leading) + dates
    }

    /// Weekday column titles starting Monday.
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    /// Groups session start dates by day (start of day).
    static func sessionsByDay<T>(_ items: [T], date: (T) -> Date, calendar: Calendar) -> [Date: [T]] {
        Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
    }
}
