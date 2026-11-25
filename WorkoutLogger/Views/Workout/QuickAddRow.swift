import SwiftUI

/// "Repeat −1 −2 −3" under the current exercise: each adds a set at once with the previous
/// set's weight and reps minus N (minimum 1). Values come from Settings.
struct QuickAddRow: View {
    let values: [Int]
    let onQuick: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Repeat")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
            ForEach(Array(values.enumerated()), id: \.offset) { _, n in
                Button {
                    onQuick(n)
                } label: {
                    Text(QuickButtons.label(n))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 14)
                        .frame(minHeight: Theme.pillHeight)
                        .background(Theme.raised, in: Capsule())
                        .frame(minHeight: Theme.minTouch)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add set with \(n) fewer reps")
            }
            Spacer()
        }
    }
}
