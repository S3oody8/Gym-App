import SwiftData
import SwiftUI

/// Sheet for the Shrug import: mapping → progress → summary.
struct ShrugImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShrugImportViewModel

    init(text: String) {
        _viewModel = State(initialValue: ShrugImportViewModel(text: text))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .mapping:
                    ShrugMappingView(viewModel: viewModel) { start() }
                case .importing(let done, let total):
                    ShrugProgressView(done: done, total: total)
                case .finished(let result):
                    ShrugSummaryView(result: result)
                case .failed(let message):
                    ContentUnavailableView("Import Failed", systemImage: "exclamationmark.triangle",
                                           description: Text(message))
                }
            }
            .navigationTitle("Import from Shrug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if case .importing = viewModel.phase {
                        EmptyView()
                    } else if case .finished = viewModel.phase {
                        EmptyView()
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if case .finished = viewModel.phase {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .interactiveDismissDisabled(isImporting)
        .task {
            switch DebugScenario.current {
            case .shrugProgress: start(batchSize: 250, delay: .seconds(1.5))
            case .shrugSummary: start()
            default: break
            }
        }
    }

    private var isImporting: Bool {
        if case .importing = viewModel.phase { return true }
        return false
    }

    private func start(batchSize: Int = 500, delay: Duration = .zero) {
        Task { await viewModel.startImport(context: context, batchSize: batchSize, batchDelay: delay) }
    }
}
