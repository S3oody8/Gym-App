import Foundation

/// `@AppStorage` keys and defaults for user settings.
enum SettingsKeys {
    static let restAlertEnabled = "restAlertEnabled"
    static let restAlertSeconds = "restAlertSeconds"
    static let backupReminderEnabled = "backupReminderEnabled"
    static let healthKitEnabled = "healthKitEnabled"

    static let defaultRestAlertEnabled = true
    static let defaultRestAlertSeconds = 180
}
