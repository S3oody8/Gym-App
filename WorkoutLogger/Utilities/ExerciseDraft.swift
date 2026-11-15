import Foundation

/// Editable values for creating or editing an exercise. Pure value type, no UI.
struct ExerciseDraft: Equatable, Sendable {
    var name: String = ""
    var primary: MuscleGroup = .chest
    var secondary: Set<MuscleGroup> = []
    var equipment: Equipment = .machine
    /// Text as typed by the user (accepts "," or "." as decimal separator).
    var incrementText: String = "2.5"

    enum ValidationError: Error, Equatable {
        case emptyName
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

    /// Secondary muscles excluding the primary, in enum order.
    var cleanedSecondary: [MuscleGroup] {
        MuscleGroup.allCases.filter { secondary.contains($0) && $0 != primary }
    }

    func validate() -> ValidationError? {
        if trimmedName.isEmpty { return .emptyName }
        if increment == nil { return .invalidIncrement }
        return nil
    }

    var isValid: Bool { validate() == nil }

    /// Formats a kg value without trailing zeros, e.g. 2.5 → "2.5", 5 → "5".
    static func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "en_US_POSIX")))
    }
}
