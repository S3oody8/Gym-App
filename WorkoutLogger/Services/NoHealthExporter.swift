import Foundation

/// Used when the app is built without HealthKit: never available, writes nothing.
@MainActor
final class NoHealthExporter: WorkoutHealthExporting {
    var isAvailable: Bool { false }
    func requestAuthorization() async throws {}
    func saveStrengthWorkout(_ interval: DateInterval) async throws {}
}
