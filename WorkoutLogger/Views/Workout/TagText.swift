import SwiftUI

/// Tiny capsule tag, e.g. "RIR 2" or "Drop".
struct TagText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Capsule().fill(Color(.tertiarySystemFill)))
    }
}
