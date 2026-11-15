import Foundation

/// Navigation destinations from the Progress tab.
enum ProgressRoute: Hashable {
    case session(WorkoutSession)
    case exercise(Exercise)
}
