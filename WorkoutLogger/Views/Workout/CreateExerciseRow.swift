import SwiftUI

/// Dashed "Create "<Name>"" row shown at the end of the picker's results.
struct CreateExerciseRow: View {
    let name: String
    let error: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create \u{201C}\(name)\u{201D}")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(error ?? "Adds it to this workout and opens the set pad")
                        .font(.footnote)
                        .foregroundStyle(error == nil ? Color.secondary : Color.red)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .accessibilityHint("Adds it to this workout and opens the set pad")
    }
}
