import Foundation

/// The "Repeat" quick buttons (SPEC §3): up to three values 1–9, set in Settings. Each adds a
/// set with the previous set's weight and reps minus N. An empty slot hides that button.
enum QuickButtons {
    static let keys = ["quickButton1", "quickButton2", "quickButton3"]
    static let defaults = ["1", "2", "3"]

    /// A slot's value: the text trimmed, with an optional leading "−" or "-", if it's 1–9.
    static func parse(_ text: String) -> Int? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first, first == "−" || first == "-" { trimmed.removeFirst() }
        guard let value = Int(trimmed), (1...9).contains(value) else { return nil }
        return value
    }

    /// What a slot keeps as the user types: at most one digit 1–9 (anything else is dropped).
    static func sanitize(_ text: String) -> String {
        text.last(where: { ("1"..."9").contains(String($0)) }).map(String.init) ?? ""
    }

    /// The visible buttons in slot order (empty or invalid slots hidden).
    static func values(from slots: [String]) -> [Int] {
        slots.compactMap(parse)
    }

    static func current(from defaults: UserDefaults = .standard) -> [Int] {
        values(from: zip(keys, Self.defaults).map { key, fallback in
            defaults.string(forKey: key) ?? fallback
        })
    }

    /// "−2"
    static func label(_ value: Int) -> String { "−\(value)" }
}
