import Foundation

/// State of the set pad (weight / reps / RIR typed on the custom keypad, ×2). Pure, no UI.
struct SetEntryForm: Equatable, Sendable {
    var weightText: String = ""
    var repsText: String = ""
    var rirText: String = ""
    var type: SetType = .working
    /// Grey hint shown while Reps is empty (last session's set 1 reps). Never saved.
    private(set) var repsHint: Int?
    /// True after ×2: the weight field holds the doubled total. Typing in Weight clears it.
    private(set) var isDoubled = false
    /// Weight text before ×2, so a second tap can undo it.
    private var weightBeforeDouble: String?
    private(set) var field: SetEntryField = .weight
    /// When true, the next digit replaces the field's text (calculator-style after pre-fill / selecting).
    private(set) var replaceOnNextInput = true

    static let maxWeightIntegerDigits = 4
    static let maxWeightFractionDigits = 2
    static let maxRepsDigits = 3
    static let rirRange = 0...5

    init(initial: SetValues? = nil, field: SetEntryField? = nil) {
        if let initial {
            weightText = WeightFormatter.string(initial.weight)
            repsText = String(initial.reps)
            rirText = initial.rir.map(String.init) ?? ""
            type = initial.type
        }
        self.field = field ?? (initial == nil ? .weight : .reps)
    }

    /// Adding a set: the prefilled weight (if any), empty reps with an optional grey hint.
    init(prefill: SetPrefill) {
        weightText = prefill.weight.map(WeightFormatter.string) ?? ""
        repsHint = prefill.repsHint
        field = prefill.field
    }

    /// ×2: doubles the weight field (rounded to 0.01) so the total is saved. Tapping again
    /// while doubled restores the per-side value.
    mutating func toggleDouble() {
        if isDoubled, let before = weightBeforeDouble {
            weightText = before
            isDoubled = false
            weightBeforeDouble = nil
        } else if let weight, weight > 0 {
            weightBeforeDouble = weightText
            weightText = WeightFormatter.string(SetPlanner.doubled(weight))
            isDoubled = true
        }
        if field == .weight { replaceOnNextInput = true }
    }

    mutating func select(_ newField: SetEntryField) {
        field = newField
        replaceOnNextInput = true
    }

    mutating func press(_ key: KeypadKey) {
        if field == .weight { clearDoubled() }
        switch key {
        case .digit(let d): typeDigit(d)
        case .decimal: typeDecimal()
        case .backspace: backspace()
        }
    }

    private mutating func clearDoubled() {
        isDoubled = false
        weightBeforeDouble = nil
    }

    // MARK: Parsed values

    var weight: Double? {
        guard !weightText.isEmpty else { return nil }
        return Double(weightText)
    }

    var reps: Int? {
        guard let value = Int(repsText), value >= 1 else { return nil }
        return value
    }

    /// nil when empty. Values outside 0–5 can't be typed.
    var rir: Int? { Int(rirText) }

    /// Valid values to save, or nil if weight/reps are missing.
    var values: SetValues? {
        guard let weight, let reps else { return nil }
        return SetValues(weight: weight, reps: reps, rir: rir, type: type)
    }

    // MARK: Editing

    private mutating func typeDigit(_ d: Int) {
        guard (0...9).contains(d) else { return }
        switch field {
        case .weight:
            var text = replaceOnNextInput ? "" : weightText
            if text == "0" { text = "" }
            let parts = text.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count == 2 {
                guard parts[1].count < Self.maxWeightFractionDigits else { return }
            } else {
                guard text.count < Self.maxWeightIntegerDigits else { return }
            }
            weightText = text + String(d)
        case .reps:
            var text = replaceOnNextInput ? "" : repsText
            if text == "0" { text = "" }
            guard text.count < Self.maxRepsDigits else { return }
            repsText = text + String(d)
        case .rir:
            guard Self.rirRange.contains(d) else { return }
            rirText = String(d)
        }
        replaceOnNextInput = false
    }

    private mutating func typeDecimal() {
        guard field == .weight else { return }
        var text = replaceOnNextInput ? "" : weightText
        guard !text.contains(".") else { return }
        if text.isEmpty { text = "0" }
        weightText = text + "."
        replaceOnNextInput = false
    }

    private mutating func backspace() {
        switch field {
        case .weight: if !weightText.isEmpty { weightText.removeLast() }
        case .reps: if !repsText.isEmpty { repsText.removeLast() }
        case .rir: rirText = ""
        }
        replaceOnNextInput = false
    }
}
