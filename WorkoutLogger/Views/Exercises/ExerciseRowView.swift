import SwiftUI

/// One row in the exercise list.
struct ExerciseRowView: View {
    let exercise: Exercise
    @AppStorage(SettingsKeys.secondaryMusclesEnabled)
    private var secondaryEnabled = SettingsKeys.defaultSecondaryMusclesEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.body)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts = [exercise.primary.rawValue]
        if secondaryEnabled, !exercise.secondary.isEmpty {
            parts[0] += " + " + exercise.secondary.map(\.rawValue).joined(separator: ", ")
        }
        parts.append(exercise.equipment.rawValue)
        return parts.joined(separator: " · ")
    }
}
