import SwiftUI

/// Slim set row: number circle, weight and reps (big number, small grey unit), RIR/Drop/PR
/// tags, last session's matching set, and a ⋯ menu (Edit / Delete). Tapping the row edits.
/// Pass nil for `onEdit`/`onDelete` for a read-only row.
struct SetRowView: View {
    let number: Int
    let values: SetValues
    var badges: PRBadges = []
    var lastText: String?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Circle().fill(Color(.tertiarySystemFill)))
                ValueUnitText(value: WeightFormatter.string(values.weight), unit: "kg")
                ValueUnitText(value: "\(values.reps)", unit: values.reps == 1 ? "rep" : "reps")
                if let rir = values.rir {
                    TagText(text: "RIR \(rir)")
                }
                if values.type == .drop {
                    TagText(text: "Drop")
                }
                if !badges.isEmpty {
                    PRBadgeView(badges: badges)
                }
                Spacer(minLength: 4)
                if let lastText {
                    Text(lastText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onEdit?() }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(onEdit == nil ? [] : .isButton)

            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit { Button("Edit", systemImage: "pencil", action: onEdit) }
                    if let onDelete { Button("Delete", systemImage: "trash", role: .destructive, action: onDelete) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Set \(number) options")
            }
        }
    }
}
