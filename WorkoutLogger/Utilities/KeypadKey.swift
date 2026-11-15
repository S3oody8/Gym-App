import Foundation

/// A key on the custom numeric keypad.
enum KeypadKey: Hashable, Sendable {
    case digit(Int)
    case decimal
    case backspace
}
