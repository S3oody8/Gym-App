import SwiftUI

/// A tappable value box in the set pop-up. The selected box receives keypad input.
struct SetEntryFieldBox: View {
    let title: String
    let text: String
    let placeholder: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text.isEmpty ? placeholder : text)
                    .font(.title.monospacedDigit().weight(.semibold))
                    .foregroundStyle(text.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(text.isEmpty ? "empty" : text)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
