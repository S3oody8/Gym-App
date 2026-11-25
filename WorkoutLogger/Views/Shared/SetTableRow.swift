import SwiftUI

/// One slim (38 pt) set row: number, weight, reps, and a NOTE with "RIR 1", "Drop" and/or a
/// small accent "PR".
struct SetTableRow: View {
    let number: Int
    let values: SetValues
    var badges: PRBadges = []
    private let columns = SetTableColumns()

    var body: some View {
        HStack(spacing: 0) {
            Text("\(number)")
                .foregroundStyle(Theme.textFaint)
                .frame(width: columns.set, alignment: .leading)
            Text(WeightFormatter.string(values.weight))
                .foregroundStyle(Theme.text)
                .frame(width: columns.kg, alignment: .leading)
            Text("\(values.reps)")
                .foregroundStyle(Theme.text)
                .frame(width: columns.reps, alignment: .leading)
            HStack(spacing: 8) {
                if let rir = values.rir { Text("RIR \(rir)") }
                if values.type == .drop { Text("Drop") }
                if !badges.isEmpty {
                    Text("PR")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.textSubtle)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.body.monospacedDigit())
        .lineLimit(1)
        .frame(minHeight: 38)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = ["Set \(number)", "\(WeightFormatter.string(values.weight)) kilograms", "\(values.reps) reps"]
        if let rir = values.rir { parts.append("RIR \(rir)") }
        if values.type == .drop { parts.append("Drop set") }
        if !badges.isEmpty { parts.append("Personal record") }
        return parts.joined(separator: ", ")
    }
}
