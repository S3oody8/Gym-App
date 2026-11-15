import Foundation

/// What to do with one Shrug exercise name.
enum ShrugMapping: Equatable, Sendable {
    /// Use the Shrug name (joins an existing exercise of the same name, ignoring case).
    case keep
    /// Use a different name.
    case rename(String)
    /// Put its sets into another exercise (an existing one, or another Shrug exercise's target).
    case merge(into: String)
}
