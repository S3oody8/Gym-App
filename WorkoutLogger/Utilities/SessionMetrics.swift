import Foundation

/// Pure session numbers and their display formats.
enum SessionMetrics {
    /// Volume in kg: Σ weight × reps over working and drop sets.
    static func load(_ sets: [SetValues]) -> Double {
        sets.filter { $0.type == .working || $0.type == .drop }
            .reduce(0) { $0 + $1.weight * Double($1.reps) }
    }

    /// Finish time of a session: the time of the last logged set, or `now` if there are no sets.
    static func finishTime(setTimes: [Date], now: Date) -> Date {
        setTimes.max() ?? now
    }

    /// "Load 4,820 kg" (rounded to whole kg).
    static func loadText(_ kg: Double) -> String {
        let style = IntegerFormatStyle<Int>.number.grouping(.automatic).locale(Locale(identifier: "en_US"))
        return "Load \(Int(kg.rounded()).formatted(style)) kg"
    }

    /// "15/11", or "15/11/2025" when not in the current year.
    static func shortDate(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.day, .month, .year], from: date)
        let currentYear = calendar.component(.year, from: now)
        let base = String(format: "%02d/%02d", parts.day ?? 0, parts.month ?? 0)
        return parts.year == currentYear ? base : "\(base)/\(parts.year ?? 0)"
    }

    /// History row title: the name, or "Workout" if unnamed.
    static func title(name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Workout" : trimmed
    }

    /// Detail screen title: "15/11 – Anterior", or just "15/11" if unnamed.
    static func detailTitle(name: String, date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let day = shortDate(date, now: now, calendar: calendar)
        return trimmed.isEmpty ? day : "\(day) – \(trimmed)"
    }
}
