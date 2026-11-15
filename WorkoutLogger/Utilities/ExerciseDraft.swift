import Foundation

/// Editable values for creating or editing an exercise. Pure value type, no UI.
struct ExerciseDraft: Equatable, Sendable {
    var name: String = ""
    var equipment: Equipment = .machine
    /// Text as typed by the user (accepts "," or "." as decimal separator).
    var incrementText: String = "2.5"

    enum ValidationError: Error, Equatable {
        case emptyName
        case duplicateName
        case invalidIncrement
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parsed weight increment in kg, or nil if not a positive number.
    var increment: Double? {
        let text = incrementText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(text), value.isFinite, value > 0 else { return nil }
        return value
    }

    /// Normalised key for duplicate detection: trimmed, case-insensitive.
    static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// `existingNames` are the names of all *other* exercises (archived included).
    func validate(existingNames: [String] = []) -> ValidationError? {
        if trimmedName.isEmpty { return .emptyName }
        let key = Self.nameKey(trimmedName)
        if existingNames.contains(where: { Self.nameKey($0) == key }) { return .duplicateName }
        if increment == nil { return .invalidIncrement }
        return nil
    }

    func isValid(existingNames: [String] = []) -> Bool {
        validate(existingNames: existingNames) == nil
    }

    static func format(_ value: Double) -> String {
        WeightFormatter.string(value)
    }
}
