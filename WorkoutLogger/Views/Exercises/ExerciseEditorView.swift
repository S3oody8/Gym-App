import SwiftData
import SwiftUI

/// Add / edit form for an exercise.
struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.secondaryMusclesEnabled)
    private var secondaryEnabled = SettingsKeys.defaultSecondaryMusclesEnabled
    @State private var viewModel: ExerciseEditorViewModel
    @FocusState private var nameFocused: Bool

    init(exercise: Exercise?) {
        _viewModel = State(initialValue: ExerciseEditorViewModel(exercise: exercise))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Lat Pulldown – Neutral", text: $viewModel.draft.name)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                }
                Section("Muscles") {
                    Picker("Primary", selection: $viewModel.draft.primary) {
                        ForEach(MuscleGroup.allCases) { muscle in
                            Text(muscle.rawValue).tag(muscle)
                        }
                    }
                    if secondaryEnabled {
                        NavigationLink {
                            SecondaryMusclePicker(
                                selection: $viewModel.draft.secondary,
                                primary: viewModel.draft.primary
                            )
                        } label: {
                            LabeledContent("Secondary", value: secondarySummary)
                        }
                    }
                }
                Section {
                    Picker("Equipment", selection: $viewModel.draft.equipment) {
                        ForEach(Equipment.allCases) { equipment in
                            Text(equipment.rawValue).tag(equipment)
                        }
                    }
                    LabeledContent("Weight increment") {
                        HStack(spacing: 4) {
                            TextField("2.5", text: $viewModel.draft.incrementText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("kg").foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    if viewModel.draft.validate() == .invalidIncrement {
                        Text("Enter a weight increment greater than 0.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(in: context) { dismiss() }
                    }
                    .disabled(!viewModel.draft.isValid)
                }
            }
            .onAppear { if viewModel.isNew { nameFocused = true } }
        }
    }

    private var secondarySummary: String {
        let list = viewModel.draft.cleanedSecondary
        return list.isEmpty ? "None" : list.map(\.rawValue).joined(separator: ", ")
    }
}
