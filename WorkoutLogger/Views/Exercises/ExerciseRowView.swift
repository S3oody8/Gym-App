import SwiftUI

/// One row in the exercise list: name (search matches highlighted), then equipment underneath.
struct ExerciseRowView: View {
    let exercise: Exercise
    var query: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HighlightedNameText(name: exercise.name, query: query)
                .font(.body)
            Text(exercise.equipment.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
