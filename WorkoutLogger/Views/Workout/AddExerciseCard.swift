import SwiftUI

/// Big dashed card with an accent ⊕ and "Add exercise", shown while the workout is empty.
/// The whole card is the button.
struct AddExerciseCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                Text("Add exercise")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(Theme.border)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
