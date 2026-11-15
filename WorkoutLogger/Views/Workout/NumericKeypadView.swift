import SwiftUI

/// Large one-handed numeric keypad: 1–9, decimal point, 0, backspace.
struct NumericKeypadView: View {
    let decimalEnabled: Bool
    let onKey: (KeypadKey) -> Void

    private let rows: [[KeypadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.decimal, .digit(0), .backspace],
    ]

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(rows.indices, id: \.self) { row in
                GridRow {
                    ForEach(rows[row], id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
    }

    private func keyButton(_ key: KeypadKey) -> some View {
        Button {
            onKey(key)
        } label: {
            Group {
                switch key {
                case .digit(let d): Text("\(d)")
                case .decimal: Text(".")
                case .backspace: Image(systemName: "delete.left")
                }
            }
            .font(.title.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(key == .decimal && !decimalEnabled)
        .opacity(key == .decimal && !decimalEnabled ? 0.3 : 1)
        .accessibilityLabel(label(for: key))
    }

    private func label(for key: KeypadKey) -> String {
        switch key {
        case .digit(let d): "\(d)"
        case .decimal: "Decimal point"
        case .backspace: "Delete"
        }
    }
}
