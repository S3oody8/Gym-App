import Foundation

/// Exercises tab order (SPEC §1): last used, most recent first, then by name.
/// Never-used exercises come after used ones.
enum ExerciseOrdering {
    static func recentFirst<T>(_ items: [T], lastUsed: (T) -> Date?, name: (T) -> String) -> [T] {
        items.sorted { a, b in
            switch (lastUsed(a), lastUsed(b)) {
            case let (x?, y?) where x != y: return x > y
            case (.some, nil): return true
            case (nil, .some): return false
            default: return name(a).localizedCaseInsensitiveCompare(name(b)) == .orderedAscending
            }
        }
    }
}
