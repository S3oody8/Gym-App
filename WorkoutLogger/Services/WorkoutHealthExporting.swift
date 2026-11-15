import Foundation

/// Writes finished workouts to Apple Health. Implemented with HealthKit only when the app is
/// built with the `HEALTHKIT` compilation condition (see SPEC section 9).
@MainActor
protocol WorkoutHealthExporting: AnyObject {
    /// False when this build has no HealthKit or the device doesn't support it.
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func saveStrengthWorkout(_ interval: DateInterval) async throws
}
