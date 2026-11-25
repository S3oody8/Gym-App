import SwiftUI

/// Inline editable workout name (e.g. "Anterior"). The text is kept in the view model and
/// saved 0.5 s after typing stops, on Return and when the field goes away.
struct WorkoutNameField: View {
    let viewModel: SessionEditorViewModel
    @FocusState private var focused: Bool

    var body: some View {
        TextField("Workout", text: Binding(
            get: { viewModel.nameDraft },
            set: { viewModel.editName($0) }
        ))
        .font(.title3.weight(.semibold))
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        .focused($focused)
        .onSubmit { viewModel.commitName() }
        .onChange(of: focused) { _, isFocused in
            if !isFocused { viewModel.commitName() }
        }
        .onDisappear { viewModel.commitName() }
    }
}
