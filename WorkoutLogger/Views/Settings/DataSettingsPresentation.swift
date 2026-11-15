import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// File exporters/importer, the Shrug import sheet and result alerts for Settings → Data.
struct DataSettingsPresentation: ViewModifier {
    @Environment(\.modelContext) private var context
    @Bindable var viewModel: DataSettingsViewModel

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: Binding(get: { viewModel.jsonDocument != nil }, set: { if !$0 { viewModel.jsonDocument = nil } }),
                document: viewModel.jsonDocument,
                contentType: .json,
                defaultFilename: DataSettingsViewModel.fileName("WorkoutLogger-backup")
            ) { viewModel.exportFinished($0) }
            .fileExporter(
                isPresented: Binding(get: { viewModel.csvDocument != nil }, set: { if !$0 { viewModel.csvDocument = nil } }),
                document: viewModel.csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: DataSettingsViewModel.fileName("WorkoutLogger-sets")
            ) { viewModel.exportFinished($0) }
            .fileImporter(isPresented: $viewModel.isImportingJSON,
                          allowedContentTypes: viewModel.importingShrug ? [.commaSeparatedText, .plainText, .text] : [.json]) { result in
                switch result {
                case .success(let url):
                    if viewModel.importingShrug {
                        viewModel.loadShrug(url)
                    } else {
                        viewModel.importJSON(from: url, context: context)
                    }
                case .failure(let error):
                    viewModel.show("Import failed", error.localizedDescription)
                }
            }
            .sheet(item: $viewModel.shrugText) { item in
                ShrugImportView(text: item.text)
            }
            .alert(viewModel.alertTitle, isPresented: Binding(
                get: { viewModel.alertMessage != nil }, set: { if !$0 { viewModel.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.alertMessage ?? "")
            }
            .task {
                // Debug-only: open the import sheet once the screen is on display.
                guard let text = DebugScenario.shrugFileText, viewModel.shrugText == nil,
                      [.shrugMapping, .shrugProgress, .shrugSummary].contains(DebugScenario.current) else { return }
                try? await Task.sleep(for: .seconds(1))
                viewModel.shrugText = .init(text: text)
            }
    }
}
