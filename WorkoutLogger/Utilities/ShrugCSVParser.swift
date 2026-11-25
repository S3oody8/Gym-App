import Foundation

/// Parses a Shrug CSV export. Built from the real sample in Fixtures/shrug_sample.csv:
/// header `Workout Start, Exercise, Weight, Unit, Reps, Reps/Secs`, comma + space separated,
/// dates "yyyy-MM-dd HH:mm" (local time), Unit "kg"/"lb", Reps/Secs "reps"/"secs".
enum ShrugCSVParser {
    enum ParseError: Error, LocalizedError, Equatable {
        case missingColumns([String])
        case empty

        var errorDescription: String? {
            switch self {
            case .missingColumns(let names): "This doesn't look like a supported workout CSV (missing: \(names.joined(separator: ", ")))."
            case .empty: "The file is empty."
            }
        }
    }

    struct Result: Equatable, Sendable {
        var rows: [ShrugRow]
        /// Data lines that couldn't be read (bad date / number / column count).
        var unreadableLines: Int
    }

    static let requiredColumns = ["Workout Start", "Exercise", "Weight", "Unit", "Reps", "Reps/Secs"]
    static let unnamedExercise = "Unnamed exercise"

    static func parse(_ text: String, timeZone: TimeZone = .current) throws -> Result {
        var lines = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !lines.isEmpty else { throw ParseError.empty }
        let header = fields(lines.removeFirst()).map { $0.replacingOccurrences(of: "\u{FEFF}", with: "") }
        var index: [String: Int] = [:]
        for (i, name) in header.enumerated() { index[name.lowercased()] = i }
        let missing = requiredColumns.filter { index[$0.lowercased()] == nil }
        guard missing.isEmpty else { throw ParseError.missingColumns(missing) }
        func col(_ name: String) -> Int { index[name.lowercased()]! }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var rows: [ShrugRow] = []
        rows.reserveCapacity(lines.count)
        var unreadable = 0
        for line in lines {
            let f = fields(line)
            guard f.count >= header.count,
                  let start = parseDate(f[col("Workout Start")], calendar: calendar),
                  let weight = Double(f[col("Weight")]), weight.isFinite, weight >= 0,
                  let reps = Int(f[col("Reps")]), reps >= 0 else {
                unreadable += 1
                continue
            }
            rows.append(ShrugRow(
                startText: f[col("Workout Start")],
                start: start,
                exercise: cleanName(f[col("Exercise")]),
                weight: weight,
                isPounds: f[col("Unit")].lowercased().hasPrefix("lb"),
                reps: reps,
                isTimed: f[col("Reps/Secs")].lowercased().hasPrefix("sec")
            ))
        }
        return Result(rows: rows, unreadableLines: unreadable)
    }

    /// Splits one CSV line (handles quoted fields), trimming spaces around each field.
    static func fields(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = Array(line).makeIterator()
        var pending: Character? = nil
        while let ch = pending ?? iterator.next() {
            pending = nil
            if inQuotes {
                if ch == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" { current.append("\"") } else { inQuotes = false; pending = next }
                    } else { inQuotes = false }
                } else { current.append(ch) }
            } else if ch == "\"" {
                inQuotes = true
            } else if ch == "," {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(ch)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }

    /// Removes invisible format characters (e.g. U+200E) and trims; empty → "Unnamed exercise".
    static func cleanName(_ raw: String) -> String {
        let visible = String(String.UnicodeScalarView(raw.unicodeScalars.filter {
            $0.properties.generalCategory != .format
        }))
        let trimmed = visible.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
        return trimmed.isEmpty ? unnamedExercise : trimmed
    }

    /// "yyyy-MM-dd HH:mm" → Date in `calendar`'s time zone.
    static func parseDate(_ text: String, calendar: Calendar) -> Date? {
        let parts = text.split(whereSeparator: { $0 == "-" || $0 == " " || $0 == ":" || $0 == "T" }).compactMap { Int($0) }
        guard parts.count >= 5 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2],
                                                  hour: parts[3], minute: parts[4],
                                                  second: parts.count > 5 ? parts[5] : 0))
    }
}
