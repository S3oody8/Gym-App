import Foundation

/// Name search used by the exercise list and pickers.
enum ExerciseSearch {
    /// Case- and diacritic-insensitive "contains" match. An empty or blank query matches everything.
    static func matches(name: String, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    /// Returns visible items: archived items are excluded unless `includeArchived` is true,
    /// then filtered by `query` and sorted by name (localized, case-insensitive).
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
            .sorted { name($0).localizedCaseInsensitiveCompare(name($1)) == .orderedAscending }
    }
}
