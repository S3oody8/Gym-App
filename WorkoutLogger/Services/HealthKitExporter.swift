#if HEALTHKIT
import Foundation
import HealthKit

/// HealthKit implementation: saves a Traditional Strength Training workout (start, end, duration).
@MainActor
final class HealthKitExporter: WorkoutHealthExporting {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
    }

    func saveStrengthWorkout(_ interval: DateInterval) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        try await builder.beginCollection(at: interval.start)
        try await builder.endCollection(at: interval.end)
        _ = try await builder.finishWorkout()
    }
}
#endif
