import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class FakeHealthExporter: WorkoutHealthExporting {
    var isAvailable = true
    var saved: [DateInterval] = []
    var error: Error?
    func requestAuthorization() async throws {}
    func saveStrengthWorkout(_ interval: DateInterval) async throws {
        if let error { throw error }
        saved.append(interval)
    }
}

@MainActor
final class HealthTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_760_000_000)

    func testIntervalRule() {
        XCTAssertEqual(HealthWorkoutPlan.interval(startedAt: t0, finishedAt: t0.addingTimeInterval(3600), setCount: 3),
                       DateInterval(start: t0, end: t0.addingTimeInterval(3600)))
        XCTAssertNil(HealthWorkoutPlan.interval(startedAt: t0, finishedAt: t0.addingTimeInterval(3600), setCount: 0))
        XCTAssertNil(HealthWorkoutPlan.interval(startedAt: t0, finishedAt: t0, setCount: 3), "imported: no duration")
        XCTAssertNil(HealthWorkoutPlan.interval(startedAt: t0, finishedAt: nil, setCount: 3))
    }

    private func liveSession(_ context: ModelContext, withSet: Bool) throws -> WorkoutSession {
        let store = WorkoutStore(context: context)
        let session = try store.startSession(at: .now.addingTimeInterval(-1800))
        if withSet {
            let bench = Exercise(name: "Bench", equipment: .barbell)
            context.insert(bench)
            try store.addSet(SetValues(weight: 80, reps: 8), to: try store.addEntry(bench, to: session))
        }
        return session
    }

    func testFinishWritesToHealthOnlyWhenEnabled() async throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "HealthTests"))
        defaults.removePersistentDomain(forName: "HealthTests")

        let fake = FakeHealthExporter()
        let on = SessionEditorViewModel(session: try liveSession(container.mainContext, withSet: true),
                                        context: container.mainContext, restAlerts: FakeRestAlerts(),
                                        health: fake, healthEnabled: { true })
        on.finish()
        await on.healthTask?.value
        XCTAssertEqual(fake.saved.count, 1)
        XCTAssertEqual(fake.saved.first?.start, on.session.startedAt)
        XCTAssertEqual(fake.saved.first?.end, on.session.finishedAt)

        let off = SessionEditorViewModel(session: try liveSession(container.mainContext, withSet: true),
                                         context: container.mainContext, restAlerts: FakeRestAlerts(),
                                         health: fake, healthEnabled: { false })
        off.finish()
        await off.healthTask?.value
        XCTAssertEqual(fake.saved.count, 1, "toggle off → nothing written")

        let empty = SessionEditorViewModel(session: try liveSession(container.mainContext, withSet: false),
                                           context: container.mainContext, restAlerts: FakeRestAlerts(),
                                           health: fake, healthEnabled: { true })
        empty.discard()
        XCTAssertNil(empty.healthTask, "discarded workouts are never written")
        XCTAssertEqual(fake.saved.count, 1)
    }

    func testExportRecordsFailureForSettings() async throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "HealthTests2"))
        defaults.removePersistentDomain(forName: "HealthTests2")
        let fake = FakeHealthExporter()
        fake.error = CocoaError(.featureUnsupported)
        await HealthSync.export(startedAt: t0, finishedAt: t0.addingTimeInterval(60), setCount: 1,
                                exporter: fake, enabled: true, defaults: defaults)
        XCTAssertTrue(defaults.string(forKey: HealthSync.lastResultKey)?.hasPrefix("Couldn't save") == true)
        fake.error = nil
        await HealthSync.export(startedAt: t0, finishedAt: t0.addingTimeInterval(60), setCount: 1,
                                exporter: fake, enabled: true, defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: HealthSync.lastResultKey), "Last workout saved to Apple Health.")
    }

    func testNoHealthBuildIsNeverAvailable() {
        XCTAssertFalse(NoHealthExporter().isAvailable)
    }
}
