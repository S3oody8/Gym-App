import SwiftUI

/// One row in an exercise list: the name (search matches highlighted) and, on the right, the
/// date it was last used (nothing if never used).
struct ExerciseRowView: View {
    let exercise: Exercise
    /// From `PRCache`, so drawing the row doesn't walk the exercise's history.
    let lastUsed: Date?
    var query: String = ""

    var body: some View {
        HStack(spacing: 8) {
            HighlightedNameText(name: exercise.name, query: query)
                .font(.body)
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let lastUsed {
                Text(HistoryFormat.day(lastUsed))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textSubtle)
            }
        }
        .frame(minHeight: Theme.minTouch)
        .contentShape(Rectangle())
    }
}
