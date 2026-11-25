import Foundation

/// Pure text for history rows and the past workout screen (SPEC §2), e.g.
/// "Mon 24/11 · 61 min · 20 sets · 6,140 kg" and "Mon 24/11 · 12:02 – 13:03".
enum HistoryFormat {
    private static let posix = Locale(identifier: "en_US_POSIX")

    /// "Mon 24/11", with "/2025" added when not in the current year.
    static func day(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let weekday = calendar.shortWeekdaySymbolsPOSIX[calendar.component(.weekday, from: date) - 1]
        return "\(weekday) \(SessionMetrics.shortDate(date, now: now, calendar: calendar))"
    }

    /// "6,140 kg" (whole kg, grouped).
    static func volume(_ kg: Double) -> String {
        let style = IntegerFormatStyle<Int>.number.grouping(.automatic).locale(Locale(identifier: "en_US"))
        return "\(Int(kg.rounded()).formatted(style)) kg"
    }

    /// "61 min" (whole minutes, never hours).
    static func minutes(_ interval: TimeInterval) -> String {
        "\(max(0, Int(interval / 60))) min"
    }

    /// "1 set" / "20 sets".
    static func sets(_ count: Int) -> String {
        "\(count) set\(count == 1 ? "" : "s")"
    }

    /// "1 PR" / "3 PRs", or nil for none.
    static func prs(_ count: Int) -> String? {
        count > 0 ? "\(count) PR\(count == 1 ? "" : "s")" : nil
    }

    /// History row line without the PR part. A zero duration (imported workouts) is left out.
    static func rowLine(start: Date, duration: TimeInterval, sets: Int, volume kg: Double,
                        now: Date = .now, calendar: Calendar = .current) -> String {
        [day(start, now: now, calendar: calendar),
         duration > 0 ? minutes(duration) : nil,
         Self.sets(sets),
         volume(kg)].compactMap { $0 }.joined(separator: " · ")
    }

    /// "12:02" (24-hour).
    static func time(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    /// "Mon 24/11 · 12:02 – 13:03", or just the day when start and end are the same minute.
    static func detailLine(start: Date, end: Date?, now: Date = .now, calendar: Calendar = .current) -> String {
        let dayText = day(start, now: now, calendar: calendar)
        guard let end, time(end, calendar: calendar) != time(start, calendar: calendar) else { return dayText }
        return "\(dayText) · \(time(start, calendar: calendar)) – \(time(end, calendar: calendar))"
    }
}

private extension Calendar {
    /// "Sun", "Mon", … regardless of the device language (the spec's format is English).
    var shortWeekdaySymbolsPOSIX: [String] {
        var c = self
        c.locale = Locale(identifier: "en_US_POSIX")
        return c.shortWeekdaySymbols
    }
}
