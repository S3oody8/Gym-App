import SwiftUI

/// Per-exercise screen: metric graph with range, then every session's sets (newest first) with PRs.
struct ExerciseProgressView: View {
    @State private var viewModel: ExerciseProgressViewModel
    @State private var editing = false

    init(exercise: Exercise) {
        _viewModel = State(initialValue: ExerciseProgressViewModel(
            exercise: exercise, metric: DebugScenario.initialMetric ?? .e1RM))
    }

    var body: some View {
        let points = viewModel.points()
        let badges = viewModel.badges
        List {
            Section {
                Picker("Metric", selection: $viewModel.metric) {
                    ForEach(ProgressMetric.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                summary(points)
                ProgressChartView(points: points, metric: viewModel.metric)
                Picker("Range", selection: $viewModel.range) {
                    ForEach(ProgressRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            } footer: {
                Text(footer)
            }
            ForEach(viewModel.history, id: \.session.id) { group in
                Section {
                    ForEach(Array(group.sets.enumerated()), id: \.element.id) { index, set in
                        SetRowView(number: index + 1, values: set.values, badges: badges[set.id] ?? [])
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                } header: {
                    Text(SessionMetrics.detailTitle(name: group.session.name, date: group.session.startedAt))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .textCase(nil)
                }
            }
        }
        .listSectionSpacing(.compact)
        .environment(\.defaultMinListRowHeight, 34)
        .navigationTitle(viewModel.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            ExerciseEditorView(exercise: viewModel.exercise)
        }
    }

    @ViewBuilder
    private func summary(_ points: [ProgressPoint]) -> some View {
        HStack {
            if let last = points.last {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Latest").font(.caption).foregroundStyle(.secondary)
                    Text(ProgressMath.label(last.value, metric: viewModel.metric))
                        .font(.headline.monospacedDigit())
                }
            }
            Spacer()
            if let best = points.map(\.value).max() {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Best").font(.caption).foregroundStyle(.secondary)
                    Text(ProgressMath.label(best, metric: viewModel.metric))
                        .font(.headline.monospacedDigit())
                }
            }
        }
    }

    private var footer: String {
        switch viewModel.metric {
        case .e1RM: "Best estimated 1RM per session (Epley, working sets of 12 reps or fewer)."
        case .topSet: "Heaviest working set per session."
        case .volume: "Σ weight × reps per session (working + drop sets)."
        }
    }
}
