import SwiftUI

/// Small grey column header: SET · KG · REPS · NOTE.
struct SetTableHeader: View {
    private let columns = SetTableColumns()

    var body: some View {
        HStack(spacing: 0) {
            Text("SET").frame(width: columns.set, alignment: .leading)
            Text("KG").frame(width: columns.kg, alignment: .leading)
            Text("REPS").frame(width: columns.reps, alignment: .leading)
            Text("NOTE").frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption2.weight(.semibold))
        .kerning(0.4)
        .foregroundStyle(Theme.textFaint)
        .accessibilityHidden(true)
    }
}
