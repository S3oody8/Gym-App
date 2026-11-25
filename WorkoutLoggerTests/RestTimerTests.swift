import SwiftData
import XCTest
@testable import WorkoutLogger

final class RestTimerMathTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    func testElapsed() {
        XCTAssertEqual(RestTimerMath.elapsed(since: nil, now: t0), 0)
        XCTAssertEqual(RestTimerMath.elapsed(since: t0, now: t0.addingTimeInterval(95)), 95)
        XCTAssertEqual(RestTimerMath.elapsed(since: t0, now: t0.addingTimeInterval(-5)), 0)
    }

    func testFireDate() {
        XCTAssertEqual(RestTimerMath.fireDate(lastSetAt: t0, alertSeconds: 180, enabled: true, now: t0),
                       t0.addingTimeInterval(180))
        XCTAssertNil(RestTimerMath.fireDate(lastSetAt: t0, alertSeconds: 180, enabled: false, now: t0))
        XCTAssertNil(RestTimerMath.fireDate(lastSetAt: nil, alertSeconds: 180, enabled: true, now: t0))
        XCTAssertNil(RestTimerMath.fireDate(lastSetAt: t0, alertSeconds: 180, enabled: true,
                                            now: t0.addingTimeInterval(180)), "already past")
    }

    func testClampAndWheels() {
        XCTAssertEqual(RestTimerMath.clampAlert(10), 30)
        XCTAssertEqual(RestTimerMath.clampAlert(700), 600)
        XCTAssertEqual(RestTimerMath.clampAlert(187), 180)
        XCTAssertEqual(RestTimerMath.clampAlert(188), 195)
        XCTAssertEqual(RestTimerMath.alertSeconds(minutes: 0, seconds: 15), 30)
        XCTAssertEqual(RestTimerMath.alertSeconds(minutes: 10, seconds: 45), 600)
        XCTAssertEqual(RestTimerMath.alertSeconds(minutes: 2, seconds: 45), 165)
    }

    func testFormat() {
        XCTAssertEqual(RestTimerMath.format(0), "0:00")
        XCTAssertEqual(RestTimerMath.format(135.9), "2:15")
        XCTAssertEqual(RestTimerMath.format(3725), "62:05")
    }

    func testSettingsDefaultsAndClamp() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "RestTimerTests"))
        defaults.removePersistentDomain(forName: "RestTimerTests")
        XCTAssertEqual(RestAlertSettings.current(from: defaults), RestAlertSettings(enabled: true, seconds: 180))
        defaults.set(false, forKey: SettingsKeys.restAlertEnabled)
        defaults.set(5, forKey: SettingsKeys.restAlertSeconds)
        XCTAssertEqual(RestAlertSettings.current(from: defaults), RestAlertSettings(enabled: false, seconds: 30))
        defaults.removePersistentDomain(forName: "RestTimerTests")
    }
}

@MainActor
final class RestAlertSchedulingTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var fake: FakeRestAlerts!
    private var settings = RestAlertSettings(enabled: true, seconds: 180)
    private var vm: SessionEditorViewModel!
    private var entry: SessionExercise!

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
        let bench = Exercise(name: "Bench", equipment: .barbell)
        context.insert(bench)
        let session = try WorkoutStore(context: context).startSession()
        fake = FakeRestAlerts()
        vm = SessionEditorViewModel(session: session, context: context, restAlerts: fake,
                                    settings: { [unowned self] in self.settings })
        vm.addExercise(bench)
        entry = session.orderedEntries.first
    }

    private func addSet() {
        vm.submit(SetValues(weight: 80, reps: 8),
                  for: SetEntryRequest(entryID: entry.id, setID: nil, exerciseName: "Bench",
                                       initial: nil))
    }

    func testEachSetSchedulesOneAlertFromItsLogTime() throws {
        addSet()
        let first = try XCTUnwrap(vm.lastSetAt)
        XCTAssertEqual(fake.scheduled.count, 1)
        XCTAssertEqual(fake.pending, first.addingTimeInterval(180))

        vm.quickAdd(to: entry, minus: 1)
        let second = try XCTUnwrap(vm.lastSetAt)
        XCTAssertEqual(fake.scheduled.count, 2)
        XCTAssertEqual(fake.pending, second.addingTimeInterval(180), "replaced, not added")
    }

    func testSettingsChangeAppliesFromNextRestPeriod() throws {
        addSet()
        settings.seconds = 60
        let set = try XCTUnwrap(entry.orderedSets.first)
        vm.submit(SetValues(weight: 85, reps: 8),
                  for: SetEntryRequest(entryID: entry.id, setID: set.id, exerciseName: "Bench",
                                       initial: set.values))
        XCTAssertEqual(fake.scheduled.count, 1, "editing a set doesn't reschedule")
        vm.quickAdd(to: entry, minus: 1)
        XCTAssertEqual(fake.scheduled.last?.seconds, 60)
    }

    func testDisabledAlertCancelsButTimerStillCounts() {
        settings.enabled = false
        addSet()
        XCTAssertTrue(fake.scheduled.isEmpty)
        XCTAssertNil(fake.pending)
        XCTAssertNotNil(vm.lastSetAt, "stopwatch still has a start time")
    }

    func testUndoingOnlySetCancelsAlertAndResetsTimer() {
        addSet()
        vm.undo()
        XCTAssertNil(vm.lastSetAt)
        XCTAssertNil(fake.pending)
    }

    func testFinishCancelsAlert() {
        addSet()
        vm.finish()
        XCTAssertNil(fake.pending)
    }
}
