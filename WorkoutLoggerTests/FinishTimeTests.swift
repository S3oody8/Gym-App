import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class FinishTimeTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var store: WorkoutStore { WorkoutStore(context: context) }
    private var bench: Exercise!
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
        bench = Exercise(name: "Bench", equipment: .barbell)
        context.insert(bench)
        try context.save()
    }

    func testFinishTimePureLogic() {
        let times = [t0.addingTimeInterval(600), t0.addingTimeInterval(3660), t0.addingTimeInterval(60)]
        XCTAssertEqual(SessionMetrics.finishTime(setTimes: times, now: t0.addingTimeInterval(9999)),
                       t0.addingTimeInterval(3660))
        XCTAssertEqual(SessionMetrics.finishTime(setTimes: [], now: t0), t0)
    }

    func testFinishWithSetsUsesLastSetTime() throws {
        let session = try store.startSession(at: t0)
        let entry = try store.addEntry(bench, to: session)
        try store.addSet(SetValues(weight: 80, reps: 8), to: entry, at: t0.addingTimeInterval(120))
        try store.addSet(SetValues(weight: 80, reps: 7), to: entry, at: t0.addingTimeInterval(3660))
        try store.finish(session, now: t0.addingTimeInterval(7200))

        XCTAssertEqual(session.finishedAt, t0.addingTimeInterval(3660))
        XCTAssertEqual(session.duration, 3540, "duration = first set → last set")
        XCTAssertEqual(HealthWorkoutPlan.interval(startedAt: session.startedAt, finishedAt: session.finishedAt,
                                                  setCount: 2)?.end, t0.addingTimeInterval(3660))
        let persisted = try ModelContext(container).fetch(FetchDescriptor<WorkoutSession>()).first
        XCTAssertEqual(persisted?.finishedAt, t0.addingTimeInterval(3660))
    }

    func testFinishWithoutSetsUsesNow() throws {
        let session = try store.startSession(at: t0)
        try store.addEntry(bench, to: session)
        try store.finish(session, now: t0.addingTimeInterval(300))
        XCTAssertEqual(session.finishedAt, t0.addingTimeInterval(300))
        XCTAssertFalse(session.isActive)
    }
}
