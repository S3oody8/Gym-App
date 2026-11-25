import SwiftData
import SwiftUI

/// Mapping screen: lb handling per exercise, timed rows that will be skipped, and
/// keep / rename / merge for every Shrug exercise name.
struct ShrugMappingView: View {
    @Bindable var viewModel: ShrugImportViewModel
    let onImport: () -> Void
    @Query(sort: \Exercise.name) private var existing: [Exercise]
    @State private var renaming: ShrugExerciseInfo?
    @State private var renameText = ""
    @State private var merging: ShrugExerciseInfo?

    var body: some View {
        List {
            Section {
                Text("\(viewModel.workoutCount) workouts · \(viewModel.importableSetCount.formatted()) sets · \(viewModel.exercises.count) exercises")
                    .font(.subheadline.weight(.semibold))
            } footer: {
                Text("All sets import as Working sets with no RIR. Imported workouts have no names; rename them later in Workouts. Importing again adds nothing.")
            }

            if !viewModel.poundExercises.isEmpty {
                Section {
                    ForEach(viewModel.poundExercises) { info in
                        poundRow(info)
                    }
                } header: {
                    Text("Exercises with lb rows (\(viewModel.poundExercises.count))")
                } footer: {
                    Text("Convert multiplies by 0.4536 and rounds to 0.1 kg. Choose “Already kg” if the file labelled kg weights as lb.")
                }
            }

            if !viewModel.timedExercises.isEmpty {
                Section("Skipped: timed rows") {
                    ForEach(viewModel.timedExercises) { info in
                        LabeledContent(info.name, value: "\(info.timedRows) row\(info.timedRows == 1 ? "" : "s")")
                    }
                }
            }

            Section("Exercises (\(viewModel.exercises.count))") {
                ForEach(viewModel.visibleExercises) { info in
                    exerciseRow(info)
                }
            }
        }
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 34)
        .searchable(text: $viewModel.searchText, prompt: "Search imported exercises")
        .safeAreaInset(edge: .bottom) {
            Button(action: onImport) {
                Text("Import \(viewModel.workoutCount) Workouts")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
            .disabled(viewModel.importableSetCount == 0)
        }
        .alert("Rename", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Exercise name", text: $renameText)
            Button("Save") {
                if let info = renaming {
                    let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.mappings[info.name] = name.isEmpty || name == info.name ? .keep : .rename(name)
                }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        } message: {
            Text(renaming?.name ?? "")
        }
        .sheet(item: $merging) { info in
            ShrugMergePickerView(source: info.name,
                                 targets: viewModel.mergeTargets(for: info.name, existing: existing)) { target in
                viewModel.mappings[info.name] = .merge(into: target)
            }
        }
    }

    private func poundRow(_ info: ShrugExerciseInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(info.name).font(.subheadline.weight(.semibold))
                Spacer()
                Text(example(info))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Picker("Unit", selection: Binding(
                get: { viewModel.convertsPounds(info.name) },
                set: { viewModel.setConvertsPounds($0, for: info.name) }
            )) {
                Text("Convert lb→kg").tag(true)
                Text("Already kg").tag(false)
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
        }
        .padding(.vertical, 2)
    }

    private func example(_ info: ShrugExerciseInfo) -> String {
        let rows = "\(info.poundRows) lb row\(info.poundRows == 1 ? "" : "s")"
        guard let lb = info.poundExample else { return rows }
        let shown = viewModel.convertsPounds(info.name)
            ? "\(WeightFormatter.string(lb)) lb → \(WeightFormatter.string(ShrugImportPlanner.kilograms(fromPounds: lb))) kg"
            : "\(WeightFormatter.string(lb)) kg"
        return "\(rows) · e.g. \(shown)"
    }

    private func exerciseRow(_ info: ShrugExerciseInfo) -> some View {
        let target = viewModel.target(for: info.name)
        let mapping = viewModel.mappings[info.name] ?? .keep
        let joinsExisting = existing.contains { ExerciseDraft.nameKey($0.name) == ExerciseDraft.nameKey(target) }
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(info.name).font(.subheadline)
                Group {
                    switch mapping {
                    case .keep: Text(joinsExisting ? "Joins existing exercise" : "New exercise")
                    case .rename: Text("Rename → \(target)")
                    case .merge: Text("Merge into \(target)")
                    }
                }
                .font(.caption)
                .foregroundStyle(mapping == .keep ? Color.secondary : Color.accentColor)
            }
            Spacer(minLength: 4)
            Text("\(info.importableRows)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Menu {
                Button("Keep", systemImage: "checkmark") { viewModel.mappings[info.name] = .keep }
                Button("Rename…", systemImage: "pencil") {
                    renameText = target
                    renaming = info
                }
                Button("Merge into…", systemImage: "arrow.triangle.merge") { merging = info }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Options for \(info.name)")
        }
    }
}
