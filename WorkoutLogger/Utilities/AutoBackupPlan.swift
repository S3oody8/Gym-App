import Foundation

/// Pure rules for the weekly automatic backup (SPEC §8): when one is due, the file name, and
/// which old files to delete.
enum AutoBackupPlan {
    static let interval: TimeInterval = 7 * 86_400
    static let keepCount = 8
    static let prefix = "WorkoutLogger-backup-"
    static let suffix = ".json"

    /// Due when there has never been one, or the last one is 7 or more days old.
    static func isDue(lastBackup: Date?, now: Date) -> Bool {
        guard let lastBackup else { return true }
        return now.timeIntervalSince(lastBackup) >= interval
    }

    /// "WorkoutLogger-backup-2026-11-23.json" (local date).
    static func fileName(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return prefix + String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0) + suffix
    }

    /// Backup files to delete so only the newest `keep` remain. Other files are never touched.
    /// The date in the name orders them (it sorts as text).
    static func filesToPrune(_ names: [String], keep: Int = keepCount) -> [String] {
        let backups = names.filter(isBackupName).sorted(by: >)
        return Array(backups.dropFirst(keep))
    }

    static func isBackupName(_ name: String) -> Bool {
        guard name.hasPrefix(prefix), name.hasSuffix(suffix) else { return false }
        let date = name.dropFirst(prefix.count).dropLast(suffix.count)
        return date.count == 10 && date.allSatisfy { $0.isNumber || $0 == "-" }
    }
}
