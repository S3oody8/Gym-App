import SwiftUI

/// A logged set: number, weight × reps, RIR, drop badge, and last session's matching set.
struct SetRowView: View {
    let number: Int
    let values: SetValues
    let lastText: String?

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 20)
            Text("\(WeightFormatter.string(values.weight)) kg × \(values.reps)")
                .font(.body.monospacedDigit().weight(.medium))
            if let rir = values.rir {
                Text("RIR \(rir)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if values.type == .drop {
                Text("Drop")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            Spacer(minLength: 8)
            if let lastText {
                Text(lastText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 36)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Tap to edit")
    }
}
