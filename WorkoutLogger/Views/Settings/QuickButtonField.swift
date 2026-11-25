import SwiftUI

/// One quick button slot in Settings: a small field showing "−N" (1–9); empty hides the button.
struct QuickButtonField: View {
    @Binding var text: String
    let slot: Int

    var body: some View {
        HStack(spacing: 0) {
            Text("−")
                .foregroundStyle(text.isEmpty ? Theme.textFaint : Theme.text)
            TextField("", text: Binding(get: { text }, set: { text = QuickButtons.sanitize($0) }))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.leading)
                .frame(width: 18)
        }
        .font(.body.monospacedDigit().weight(.semibold))
        .padding(.horizontal, 10)
        .frame(height: Theme.pillHeight)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quick button \(slot)")
        .accessibilityValue(text.isEmpty ? "hidden" : "minus \(text)")
    }
}
