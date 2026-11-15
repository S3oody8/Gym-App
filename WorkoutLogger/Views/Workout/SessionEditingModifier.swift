import SwiftUI

/// Sheets, alerts and haptics shared by the live workout and the past-session editor.
struct SessionEditingModifier: ViewModifier {
    @Bindable var viewModel: SessionEditorViewModel
    @Binding var showPicker: Bool
    @Binding var showSaveTemplate: Bool
    @State private var templateName = ""

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { exercise in
                    viewModel.addExercise(exercise)
                }
            }
            .sheet(item: $viewModel.entryRequest) { request in
                SetEntrySheet(request: request) { values in
                    viewModel.submit(values, for: request)
                }
            }
            .alert("Save as Template", isPresented: $showSaveTemplate) {
                TextField("Template name", text: $templateName)
                Button("Save") {
                    viewModel.saveTemplate(named: templateName)
                    templateName = ""
                }
                .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel", role: .cancel) { templateName = "" }
            } message: {
                Text("Saves this session's exercises in order. No sets or weights are saved.")
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { if !$0 { viewModel.saveErrorMessage = nil } }
            )) {
                Button("Retry") { viewModel.retrySave() }
                Button("Dismiss", role: .cancel) {}
            } message: {
                Text("Your last change is not saved yet and may be lost if the app closes.\n\n\(viewModel.saveErrorMessage ?? "")")
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.addedSetCount)
    }
}
