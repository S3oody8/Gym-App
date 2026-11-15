import Foundation

/// Pure CSV export: one row per set (date, session, exercise, set #, type, weight, reps, RIR).
enum CSVExporter {
    static let header = ["date", "session", "exercise", "set", "type", "weight_kg", "reps", "rir"]

    static func csv(_ rows: [CSVRow], timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let lines = rows.map { row -> String in
            [
                dateText(row.date, calendar: calendar),
                row.session,
                row.exercise,
                String(row.setNumber),
                row.type.rawValue,
                WeightFormatter.string(row.weight),
                String(row.reps),
                row.rir.map(String.init) ?? "",
            ].map(escape).joined(separator: ",")
        }
        return ([header.joined(separator: ",")] + lines).joined(separator: "\n") + "\n"
    }

    /// Quotes a field if it contains a comma, quote or newline; doubles inner quotes.
    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// "2026-11-16 18:05" in local time.
    static func dateText(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(format: "%04d-%02d-%02d %02d:%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0)
    }
}
