import SwiftUI

/// −1 / −2 / −3 instant sets and the "+ Set" pop-up button.
struct QuickAddRow: View {
    let canQuickAdd: Bool
    let onQuick: (Int) -> Void
    let onAddSet: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { n in
                Button {
                    onQuick(n)
                } label: {
                    Text("−\(n)")
                        .font(.headline.monospacedDigit())
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(!canQuickAdd)
                .accessibilityLabel("Add set with \(n) fewer reps")
            }
            Button(action: onAddSet) {
                Label("Set", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add set")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }
}
