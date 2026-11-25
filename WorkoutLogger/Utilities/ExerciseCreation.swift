import Foundation

/// "Create from search" rules for the exercise picker. Pure logic, no UI.
enum ExerciseCreation {
    /// The name a query creates: trimmed, single-spaced, each word's first letter capitalised
    /// (the rest kept as typed, so "RDL" stays "RDL"). Nil for a blank query.
    static func name(from query: String) -> String? {
        let words = ExerciseSearch.words(query)
        guard !words.isEmpty else { return nil }
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    /// The name to offer in the "Create" row, or nil when the query is blank or an exercise
    /// in `names` already has exactly that name (trimmed, ignoring case).
    static func offeredName(for query: String, among names: [String]) -> String? {
        guard let name = name(from: query) else { return nil }
        let typed = ExerciseDraft.nameKey(query)
        let created = ExerciseDraft.nameKey(name)
        let taken = names.contains { [typed, created].contains(ExerciseDraft.nameKey($0)) }
        return taken ? nil : name
    }
}
