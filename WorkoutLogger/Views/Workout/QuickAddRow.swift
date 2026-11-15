import SwiftUI

/// Slim row of −1 / −2 / −3 chips under the last set: adds a set instantly with the same
/// weight and fewer reps.
struct QuickAddRow: View {
    let onQuick: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { n in
                Button("−\(n)") { onQuick(n) }
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Add set with \(n) fewer reps")
            }
            Spacer()
        }
    }
}
