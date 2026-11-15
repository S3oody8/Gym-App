import Foundation

/// State of the set pop-up (weight / reps / RIR typed on the custom keypad). Pure, no UI.
struct SetEntryForm: Equatable, Sendable {
    var weightText: String = ""
    var repsText: String = ""
    var rirText: String = ""
    var type: SetType = .working
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

    mutating func select(_ newField: SetEntryField) {
        field = newField
        replaceOnNextInput = true
    }

    mutating func press(_ key: KeypadKey) {
        switch key {
        case .digit(let d): typeDigit(d)
        case .decimal: typeDecimal()
        case .backspace: backspace()
        }
    }

    mutating func stepWeight(by increment: Double, up: Bool) {
        let current = weight ?? 0
        weightText = WeightFormatter.string(SetPlanner.step(weight: current, by: increment, up: up))
        if field == .weight { replaceOnNextInput = true }
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
