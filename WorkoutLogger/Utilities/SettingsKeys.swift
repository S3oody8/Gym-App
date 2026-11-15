import Foundation

/// `@AppStorage` keys and defaults for user settings.
enum SettingsKeys {
    static let secondaryMusclesEnabled = "secondaryMusclesEnabled"
    static let restAlertEnabled = "restAlertEnabled"
    static let restAlertSeconds = "restAlertSeconds"
    static let backupReminderEnabled = "backupReminderEnabled"
    static let healthKitEnabled = "healthKitEnabled"

    static let defaultSecondaryMusclesEnabled = true
    static let defaultRestAlertEnabled = true
    static let defaultRestAlertSeconds = 180
}
