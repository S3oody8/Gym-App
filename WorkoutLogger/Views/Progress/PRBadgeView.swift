import SwiftUI

/// Tiny trophy tag for a PR ("PR kg", "PR reps").
struct PRBadgeView: View {
    let badges: PRBadges

    var body: some View {
        HStack(spacing: 4) {
            if badges.contains(.weight) { tag("kg") }
            if badges.contains(.reps) { tag("reps") }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func tag(_ text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "trophy.fill")
            Text("PR \(text)")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.orange)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(Capsule().fill(Color.orange.opacity(0.15)))
    }

    private var accessibilityText: String {
        var parts: [String] = []
        if badges.contains(.weight) { parts.append("Heaviest weight PR") }
        if badges.contains(.reps) { parts.append("Most reps PR") }
        return parts.joined(separator: ", ")
    }
}
