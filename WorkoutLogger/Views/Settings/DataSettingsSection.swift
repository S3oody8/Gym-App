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
            Menu {
                Button {
                    viewModel.exportJSON(context: context)
                } label: {
                    Text("Backup (JSON)")
                    Text("Everything, to restore later")
                }
                Button {
                    viewModel.exportCSV(context: context)
                } label: {
                    Text("Spreadsheet (CSV)")
                    Text("All sets, opens in Excel")
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            Menu {
                Button("Backup (JSON)") {
                    viewModel.importingShrug = false
                    viewModel.isImportingJSON = true
                }
                Button("Workout CSV") {
                    viewModel.importingShrug = true
                    viewModel.isImportingJSON = true
                }
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            Toggle("Weekly backup reminder", isOn: $reminderEnabled)
        } header: {
            SectionLabel("Data")
        } footer: {
            Text("Import takes a backup (JSON) or a workout CSV.")
                .foregroundStyle(Theme.textSubtle)
        }
        .onChange(of: reminderEnabled) { _, enabled in
            if enabled { RestAlertNotifier.shared.requestAuthorization() }
            BackupReminder.sync(enabled: enabled)
        }
    }
}
