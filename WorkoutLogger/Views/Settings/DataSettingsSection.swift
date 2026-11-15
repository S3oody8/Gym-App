import SwiftData
import SwiftUI

/// Settings → Data rows. Presentation (file pickers, sheet, alerts) lives in
/// `DataSettingsPresentation`, applied to the whole Form so list re-layout can't dismiss it.
struct DataSettingsSection: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.backupReminderEnabled)
    private var reminderEnabled = SettingsKeys.defaultBackupReminderEnabled
    let viewModel: DataSettingsViewModel

    var body: some View {
        Section {
            Button("Export backup (JSON)", systemImage: "square.and.arrow.up") {
                viewModel.exportJSON(context: context)
            }
            Button("Export to CSV", systemImage: "tablecells") {
                viewModel.exportCSV(context: context)
            }
            Button("Import backup (JSON)", systemImage: "square.and.arrow.down") {
                viewModel.importingShrug = false
                viewModel.isImportingJSON = true
            }
            Button("Import from Shrug (CSV)", systemImage: "arrow.down.doc") {
                viewModel.importingShrug = true
                viewModel.isImportingJSON = true
            }
            Toggle("Weekly backup reminder", isOn: $reminderEnabled)
        } header: {
            Text("Data")
        } footer: {
            Text("Backups include every exercise, workout and template. Importing a backup only adds what isn't already here; nothing is overwritten. The reminder comes on Sundays at 19:00.")
        }
        .onChange(of: reminderEnabled) { _, enabled in
            if enabled { RestAlertNotifier.shared.requestAuthorization() }
            BackupReminder.sync(enabled: enabled)
        }
    }
}
