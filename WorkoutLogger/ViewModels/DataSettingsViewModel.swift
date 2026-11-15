import Foundation
import Observation
import SwiftData

/// Settings → Data: export backup / CSV and import backup.
@MainActor
@Observable
final class DataSettingsViewModel {
    var jsonDocument: JSONBackupDocument?
    var csvDocument: CSVExportDocument?
    var isImportingJSON = false
    /// Message for the result alert (success or failure).
    var alertTitle = ""
    var alertMessage: String?

    func exportJSON(context: ModelContext) {
        do {
            jsonDocument = JSONBackupDocument(data: try BackupCodec.encode(BackupService(context: context).makeBackup()))
        } catch {
            show("Export failed", error.localizedDescription)
        }
    }

    func exportCSV(context: ModelContext) {
        do {
            csvDocument = CSVExportDocument(text: CSVExporter.csv(try BackupService(context: context).csvRows()))
        } catch {
            show("Export failed", error.localizedDescription)
        }
    }

    func importJSON(from url: URL, context: ModelContext) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let file = try BackupCodec.decode(try Data(contentsOf: url))
            let summary = try BackupService(context: context).importBackup(file)
            show("Import complete", summary.message)
        } catch {
            context.rollback()
            show("Import failed", error.localizedDescription)
        }
    }

    func exportFinished(_ result: Result<URL, Error>) {
        jsonDocument = nil
        csvDocument = nil
        if case .failure(let error) = result, (error as? CocoaError)?.code != .userCancelled {
            show("Export failed", error.localizedDescription)
        }
    }

    func show(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
    }

    static func fileName(_ prefix: String, date: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%@-%04d-%02d-%02d", prefix, c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
