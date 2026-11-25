import Foundation
import SwiftData

/// Weekly automatic backup to the app's Documents folder (visible in Files under
/// On My iPhone › WorkoutLogger). Runs when the app comes to the foreground.
@MainActor
enum AutoBackup {
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKeys.autoBackupEnabled) == nil
            ? SettingsKeys.defaultAutoBackupEnabled
            : UserDefaults.standard.bool(forKey: SettingsKeys.autoBackupEnabled)
    }

    static var lastBackup: Date? {
        let value = UserDefaults.standard.double(forKey: SettingsKeys.lastAutoBackup)
        return value > 0 ? Date(timeIntervalSince1970: value) : nil
    }

    static var documents: URL {
        URL.documentsDirectory
    }

    /// Writes a backup if the switch is on and one is due. Encoding happens here (it reads the
    /// store); writing the file and pruning run off the main thread.
    static func runIfDue(context: ModelContext, now: Date = .now) {
        guard isEnabled, AutoBackupPlan.isDue(lastBackup: lastBackup, now: now) else { return }
        let data: Data
        do {
            data = try BackupCodec.encode(BackupService(context: context).makeBackup(now: now))
        } catch {
            return
        }
        let folder = documents
        let name = AutoBackupPlan.fileName(for: now)
        Task.detached(priority: .utility) {
            do {
                try write(data, named: name, in: folder)
                await MainActor.run {
                    UserDefaults.standard.set(now.timeIntervalSince1970, forKey: SettingsKeys.lastAutoBackup)
                }
            } catch {
                // Tried again next time the app comes to the foreground.
            }
        }
    }

    /// Writes the file atomically, then deletes all but the newest backups.
    nonisolated static func write(_ data: Data, named name: String, in folder: URL) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: folder.appending(path: name), options: .atomic)
        let names = try manager.contentsOfDirectory(atPath: folder.path(percentEncoded: false))
        for old in AutoBackupPlan.filesToPrune(names) {
            try? manager.removeItem(at: folder.appending(path: old))
        }
    }
}
