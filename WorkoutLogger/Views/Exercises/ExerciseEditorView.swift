import SwiftData
import SwiftUI

/// Add / edit form for an exercise, with Archive / Unarchive / Delete for existing ones.
struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.secondaryMusclesEnabled)
    private var secondaryEnabled = SettingsKeys.defaultSecondaryMusclesEnabled
    @Query private var allExercises: [Exercise]
    @State private var viewModel: ExerciseEditorViewModel
    @State private var library = ExerciseLibraryViewModel()
    @State private var confirmDelete = false
    @FocusState private var nameFocused: Bool

    init(exercise: Exercise?) {
        _viewModel = State(initialValue: ExerciseEditorViewModel(exercise: exercise))
    }

    private var validationError: ExerciseDraft.ValidationError? {
        viewModel.validationError(among: allExercises)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Lat Pulldown – Neutral", text: $viewModel.draft.name)
                        .focused($nameFocused)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    if validationError == .duplicateName {
                        Text("An exercise with this name already exists.")
                            .foregroundStyle(.red)
                    }
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
                    if validationError == .invalidIncrement {
                        Text("Enter a weight increment greater than 0.")
                            .foregroundStyle(.red)
                    }
                }
                if let exercise = viewModel.exercise {
                    lifecycleSection(exercise)
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
                    .disabled(validationError != nil)
                }
            }
            .confirmationDialog(
                "Delete \(viewModel.exercise?.name ?? "exercise")?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let exercise = viewModel.exercise, library.delete(exercise, in: context) {
                        dismiss()
                    }
                }
            } message: {
                Text("This exercise has no history. It will also be removed from any templates. This can't be undone.")
            }
            .alert("Couldn't save", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    viewModel.saveErrorMessage = nil
                    library.saveErrorMessage = nil
                }
            } message: {
                Text(viewModel.saveErrorMessage ?? library.saveErrorMessage ?? "")
            }
            .onAppear {
                if viewModel.isNew { nameFocused = true }
            }
        }
    }

    @ViewBuilder
    private func lifecycleSection(_ exercise: Exercise) -> some View {
        Section {
            if exercise.isArchived {
                Button("Unarchive Exercise", systemImage: "tray.and.arrow.up") {
                    if library.setArchived(false, for: exercise, in: context) { dismiss() }
                }
            } else if exercise.hasHistory {
                Button("Archive Exercise", systemImage: "archivebox") {
                    if library.setArchived(true, for: exercise, in: context) { dismiss() }
                }
                .foregroundStyle(.orange)
            } else {
                Button("Delete Exercise", systemImage: "trash", role: .destructive) {
                    confirmDelete = true
                }
            }
        } footer: {
            if exercise.isArchived {
                Text("Archived exercises are hidden from pickers and search. History is kept.")
            } else if exercise.hasHistory {
                Text("This exercise has history, so it can't be deleted. Archiving hides it from pickers and search and keeps its history.")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.saveErrorMessage != nil || library.saveErrorMessage != nil },
            set: { if !$0 { viewModel.saveErrorMessage = nil; library.saveErrorMessage = nil } }
        )
    }

    private var secondarySummary: String {
        let list = viewModel.draft.cleanedSecondary
        return list.isEmpty ? "None" : list.map(\.rawValue).joined(separator: ", ")
    }
}
