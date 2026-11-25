import SwiftUI

/// Small caps-style section label, e.g. "THIS WEEK" (13 pt, muted).
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.footnote.weight(.semibold))
            .kerning(0.4)
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
