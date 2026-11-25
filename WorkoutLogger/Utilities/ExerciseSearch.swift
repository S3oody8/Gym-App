import Foundation

/// Name search used by the exercise list and pickers.
///
/// The query is split on whitespace. A name matches when every word appears somewhere in it,
/// in any order and as part of a word, ignoring case and accents ("neutral lat" finds
/// "Lat Pulldown – Neutral"). Names that start with the first word rank first, then A–Z.
enum ExerciseSearch {
    private static let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    /// The query's words (split on whitespace, empties dropped).
    static func words(_ query: String) -> [String] {
        query.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    /// True when every query word appears in `name`. A blank query matches everything.
    static func matches(name: String, query: String) -> Bool {
        words(query).allSatisfy { name.range(of: $0, options: options) != nil }
    }

    /// True when `name` starts with the query's first word (case- and accent-insensitive).
    static func startsWithFirstWord(name: String, query: String) -> Bool {
        guard let first = words(query).first else { return false }
        return name.range(of: first, options: options.union(.anchored)) != nil
    }

    /// Ranking order: names starting with the first word first, then alphabetical.
    static func ranksBefore(_ a: String, _ b: String, query: String) -> Bool {
        let aPrefix = startsWithFirstWord(name: a, query: query)
        let bPrefix = startsWithFirstWord(name: b, query: query)
        if aPrefix != bPrefix { return aPrefix }
        return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
    }

    /// Every occurrence of every query word in `name`, merged where they overlap or touch,
    /// in ascending order. Used to highlight matches.
    static func matchRanges(name: String, query: String) -> [Range<String.Index>] {
        var found: [Range<String.Index>] = []
        for word in words(query) {
            var searchStart = name.startIndex
            while searchStart < name.endIndex,
                  let range = name.range(of: word, options: options, range: searchStart..<name.endIndex) {
                found.append(range)
                searchStart = range.upperBound
            }
        }
        found.sort { $0.lowerBound < $1.lowerBound }
        var merged: [Range<String.Index>] = []
        for range in found {
            if let last = merged.last, range.lowerBound <= last.upperBound {
                merged[merged.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
            } else {
                merged.append(range)
            }
        }
        return merged
    }

    /// Returns visible items: archived items are excluded unless `includeArchived` is true,
    /// then filtered by `query` and ranked (see `ranksBefore`).
    static func filter<T>(
        _ items: [T],
        query: String,
        includeArchived: Bool = false,
        name: (T) -> String,
        isArchived: (T) -> Bool
    ) -> [T] {
        items
            .filter { includeArchived || !isArchived($0) }
            .filter { matches(name: name($0), query: query) }
            .sorted { ranksBefore(name($0), name($1), query: query) }
    }
}
