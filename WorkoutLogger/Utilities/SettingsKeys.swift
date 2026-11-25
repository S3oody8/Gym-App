import Foundation

/// `@AppStorage` keys and defaults for user settings.
enum SettingsKeys {
    static let restAlertEnabled = "restAlertEnabled"
    static let restAlertSeconds = "restAlertSeconds"
    static let autoBackupEnabled = "autoBackupEnabled"
    /// Time of the last weekly backup (seconds since 1970).
    static let lastAutoBackup = "lastAutoBackup"
    static let healthKitEnabled = "healthKitEnabled"
    static let showDoubleButton = "showDoubleButton"
    static let liveActivityEnabled = "liveActivityEnabled"

    static let defaultRestAlertEnabled = true
    static let defaultRestAlertSeconds = 180
    static let defaultAutoBackupEnabled = true
    static let defaultShowDoubleButton = true
    static let defaultLiveActivityEnabled = true
}
