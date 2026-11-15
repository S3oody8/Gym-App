import SwiftUI

/// Inline editable workout name (e.g. "Anterior"). Saves as you type.
struct WorkoutNameField: View {
    let viewModel: SessionEditorViewModel

    var body: some View {
        TextField("Workout name (e.g. Anterior)", text: Binding(
            get: { viewModel.session.name },
            set: { viewModel.rename(to: $0) }
        ))
        .font(.title3.weight(.semibold))
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
    }
}
