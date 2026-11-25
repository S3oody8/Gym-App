import Foundation

/// Groups finished workouts (newest first) under THIS WEEK / LAST WEEK / <Month Year>.
/// Weeks run Monday–Sunday.
enum HistoryGrouping {
    struct Group<T>: Identifiable {
        let title: String
        let items: [T]
        var id: String { title }
    }

    static func title(for date: Date, now: Date, calendar: Calendar) -> String {
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)!
        if thisWeek.contains(date) || date >= thisWeek.end { return "This week" }
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek.start)!
        if date >= lastWeekStart { return "Last week" }
        var c = calendar
        c.locale = Locale(identifier: "en_US_POSIX")
        let parts = c.dateComponents([.year, .month], from: date)
        return "\(c.standaloneMonthSymbols[(parts.month ?? 1) - 1]) \(parts.year ?? 0)"
    }

    /// Keeps the input order (pass newest first) and groups consecutive items by title.
    static func groups<T>(_ items: [T], date: (T) -> Date, now: Date = .now,
                          calendar: Calendar = CalendarMath.mondayCalendar()) -> [Group<T>] {
        var result: [Group<T>] = []
        var currentTitle: String?
        var current: [T] = []
        for item in items {
            let title = title(for: date(item), now: now, calendar: calendar)
            if title != currentTitle, let currentTitle {
                result.append(Group(title: currentTitle, items: current))
                current = []
            }
            currentTitle = title
            current.append(item)
        }
        if let currentTitle { result.append(Group(title: currentTitle, items: current)) }
        return result
    }
}
