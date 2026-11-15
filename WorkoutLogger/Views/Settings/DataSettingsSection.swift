import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Data: backup/export/import buttons and the weekly backup reminder.
struct DataSettingsSection: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.backupReminderEnabled)
    private var reminderEnabled = SettingsKeys.defaultBackupReminderEnabled
    @State private var viewModel = DataSettingsViewModel()
    @State private var importingShrug = false
    @State private var shrugText: ShrugText?

    /// Identifiable wrapper so the import sheet gets a fresh view model per file.
    struct ShrugText: Identifiable {
        let id = UUID()
        let text: String
    }

    private func loadShrug(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
            shrugText = ShrugText(text: text)
        } catch {
            viewModel.show("Import failed", error.localizedDescription)
        }
    }

    var body: some View {
        Section {
            Button("Export backup (JSON)", systemImage: "square.and.arrow.up") {
                viewModel.exportJSON(context: context)
            }
            Button("Export to CSV", systemImage: "tablecells") {
                viewModel.exportCSV(context: context)
            }
            Button("Import backup (JSON)", systemImage: "square.and.arrow.down") {
                importingShrug = false
                viewModel.isImportingJSON = true
            }
            Button("Import from Shrug (CSV)", systemImage: "arrow.down.doc") {
                importingShrug = true
                viewModel.isImportingJSON = true
            }
            Toggle("Weekly backup reminder", isOn: $reminderEnabled)
        } header: {
            Text("Data")
        } footer: {
            Text("Backups include every exercise, workout and template. Importing a backup only adds what isn't already here; nothing is overwritten. The reminder comes on Sundays at 19:00.")
        }
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
                      allowedContentTypes: importingShrug ? [.commaSeparatedText, .plainText, .text] : [.json]) { result in
            switch result {
            case .success(let url):
                if importingShrug {
                    loadShrug(url)
                } else {
                    viewModel.importJSON(from: url, context: context)
                }
            case .failure(let error):
                viewModel.show("Import failed", error.localizedDescription)
            }
        }
        .sheet(item: $shrugText) { item in
            ShrugImportView(text: item.text)
        }
        .onAppear {
            if let text = DebugScenario.shrugFileText, shrugText == nil,
               [.shrugMapping, .shrugProgress, .shrugSummary].contains(DebugScenario.current) {
                shrugText = ShrugText(text: text)
            }
        }
        .alert(viewModel.alertTitle, isPresented: Binding(
            get: { viewModel.alertMessage != nil }, set: { if !$0 { viewModel.alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .onChange(of: reminderEnabled) { _, enabled in
            if enabled { RestAlertNotifier.shared.requestAuthorization() }
            BackupReminder.sync(enabled: enabled)
        }
    }
}
