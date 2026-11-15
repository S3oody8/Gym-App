import Foundation

/// Picks the Health exporter for this build and records the last export result for Settings.
@MainActor
enum HealthSync {
    static let shared: WorkoutHealthExporting = {
        #if HEALTHKIT
        return HealthKitExporter()
        #else
        return NoHealthExporter()
        #endif
    }()

    /// True when this build includes HealthKit.
    static var isCompiledIn: Bool {
        #if HEALTHKIT
        return true
        #else
        return false
        #endif
    }

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.healthKitEnabled)
    }

    static let lastResultKey = "healthLastResult"

    /// Saves a finished session if the setting is on; records success/failure text for Settings.
    static func export(startedAt: Date, finishedAt: Date?, setCount: Int,
                       exporter: WorkoutHealthExporting, enabled: Bool,
                       defaults: UserDefaults = .standard) async {
        guard enabled, exporter.isAvailable,
              let interval = HealthWorkoutPlan.interval(startedAt: startedAt, finishedAt: finishedAt, setCount: setCount)
        else { return }
        do {
            try await exporter.saveStrengthWorkout(interval)
            defaults.set("Last workout saved to Apple Health.", forKey: lastResultKey)
        } catch {
            defaults.set("Couldn't save the last workout to Apple Health: \(error.localizedDescription)", forKey: lastResultKey)
        }
    }
}
