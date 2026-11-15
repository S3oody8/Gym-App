import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Data: backup/export/import buttons and the weekly backup reminder.
struct DataSettingsSection: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.backupReminderEnabled)
    private var reminderEnabled = SettingsKeys.defaultBackupReminderEnabled
    @State private var viewModel = DataSettingsViewModel()

    var body: some View {
        Section {
            Button("Export backup (JSON)", systemImage: "square.and.arrow.up") {
                viewModel.exportJSON(context: context)
            }
            Button("Export to CSV", systemImage: "tablecells") {
                viewModel.exportCSV(context: context)
            }
            Button("Import backup (JSON)", systemImage: "square.and.arrow.down") {
                viewModel.isImportingJSON = true
            }
            Button("Import from Shrug (CSV)", systemImage: "arrow.down.doc") {}
                .disabled(true)
            Toggle("Weekly backup reminder", isOn: $reminderEnabled)
        } header: {
            Text("Data")
        } footer: {
            Text("Backups include every exercise, workout and template. Importing a backup only adds what isn't already here; nothing is overwritten. The reminder comes on Sundays at 19:00. Shrug import arrives in the next update.")
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
        .fileImporter(isPresented: $viewModel.isImportingJSON, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): viewModel.importJSON(from: url, context: context)
            case .failure(let error): viewModel.show("Import failed", error.localizedDescription)
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
