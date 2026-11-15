import Foundation
import UserNotifications

/// Weekly local notification reminding the user to export a backup (Sundays 19:00).
@MainActor
enum BackupReminder {
    static let identifier = "backup-reminder"

    /// Sunday (weekday 1) at 19:00 local time.
    static var triggerComponents: DateComponents {
        DateComponents(hour: 19, minute: 0, weekday: 1)
    }

    /// Schedules or removes the reminder to match the setting. Safe to call repeatedly.
    static func sync(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Back up your workouts"
        content.body = "Open Settings → Data → Export backup (JSON) and save it to Files."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger),
                   withCompletionHandler: nil)
    }

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKeys.backupReminderEnabled) == nil
            ? SettingsKeys.defaultBackupReminderEnabled
            : UserDefaults.standard.bool(forKey: SettingsKeys.backupReminderEnabled)
    }
}
