import XCTest
@testable import WorkoutLogger

@MainActor
final class FakeRestActivities: RestActivityControlling {
    private(set) var shown: [RestPeriod] = []
    private(set) var endCount = 0
    func show(_ period: RestPeriod) { shown.append(period) }
    func end() { endCount += 1 }
}

final class RestRingMathTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    func testRingProgressIsElapsedOverAlertCappedAtOne() {
        XCTAssertEqual(RestTimerMath.progress(since: t0, alertSeconds: 180, now: t0), 0)
        XCTAssertEqual(RestTimerMath.progress(since: t0, alertSeconds: 180, now: t0.addingTimeInterval(90)), 0.5)
        XCTAssertEqual(RestTimerMath.progress(since: t0, alertSeconds: 180, now: t0.addingTimeInterval(400)), 1)
        XCTAssertEqual(RestTimerMath.progress(since: t0, alertSeconds: 0, now: t0.addingTimeInterval(5)), 1)
    }

    func testAdjustLimits() {
        XCTAssertEqual(RestTimerMath.adjustedAlert(180, by: 30, elapsed: 10), 210)
        XCTAssertEqual(RestTimerMath.adjustedAlert(180, by: -30, elapsed: 10), 150)
        XCTAssertEqual(RestTimerMath.adjustedAlert(45, by: -30, elapsed: 0), 30, "never below 0:30")
        XCTAssertEqual(RestTimerMath.adjustedAlert(585, by: 30, elapsed: 0), 600, "never above 10:00")
        XCTAssertEqual(RestTimerMath.adjustedAlert(180, by: -30, elapsed: 170), 170, "never below elapsed")
        XCTAssertEqual(RestTimerMath.adjustedAlert(180, by: -30, elapsed: 170.4), 171, "elapsed rounded up")
        XCTAssertEqual(RestTimerMath.adjustedAlert(600, by: -30, elapsed: 650), 600, "unchanged once past 10:00")
    }
}

@MainActor
final class RestTimerStoreTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)
    private let session = UUID()
    private var alerts: FakeRestAlerts!
    private var activities: FakeRestActivities!
    private var settings = RestAlertSettings(enabled: true, seconds: 180)
    private var defaults: UserDefaults!

    override func setUp() async throws {
        alerts = FakeRestAlerts()
        activities = FakeRestActivities()
        defaults = UserDefaults(suiteName: "RestTimerStoreTests")
        defaults.removePersistentDomain(forName: "RestTimerStoreTests")
    }

    private func makeStore() -> RestTimerStore {
        RestTimerStore(alerts: alerts, activities: activities, settings: { [unowned self] in self.settings },
                       defaults: defaults)
    }

    func testSetStartsPeriodAlertAndActivity() {
        let store = makeStore()
        store.sync(sessionID: session, lastSetAt: t0, now: t0)
        XCTAssertEqual(store.visiblePeriod(for: session)?.alertSeconds, 180)
        XCTAssertEqual(alerts.pending, t0.addingTimeInterval(180))
        XCTAssertEqual(activities.shown.count, 1)
        store.sync(sessionID: session, lastSetAt: t0, now: t0.addingTimeInterval(5))
        XCTAssertEqual(alerts.scheduled.count, 1, "same set: nothing changes")
    }

    func testAdjustMovesThisPeriodOnly() {
        let store = makeStore()
        store.sync(sessionID: session, lastSetAt: t0, now: t0)
        store.adjust(by: 30, now: t0.addingTimeInterval(20))
        XCTAssertEqual(store.period?.alertSeconds, 210)
        XCTAssertEqual(alerts.pending, t0.addingTimeInterval(210))
        XCTAssertEqual(activities.shown.last?.alertSeconds, 210)

        let next = t0.addingTimeInterval(300)
        store.sync(sessionID: session, lastSetAt: next, now: next)
        XCTAssertEqual(store.period?.alertSeconds, 180, "next rest period uses Settings again")
    }

    func testSkipHidesTimerAndCancelsAlertAndActivity() {
        let store = makeStore()
        store.sync(sessionID: session, lastSetAt: t0, now: t0)
        store.skip()
        XCTAssertNil(store.visiblePeriod(for: session))
        XCTAssertNil(alerts.pending)
        XCTAssertEqual(activities.endCount, 1)
        store.adjust(by: 30, now: t0)
        XCTAssertNil(alerts.pending, "no alert comes back after skip")

        store.sync(sessionID: session, lastSetAt: t0.addingTimeInterval(60), now: t0.addingTimeInterval(60))
        XCTAssertNotNil(store.visiblePeriod(for: session), "shows again on the next set")
    }

    func testEndAndPersistence() {
        let store = makeStore()
        store.sync(sessionID: session, lastSetAt: t0, now: t0)
        store.adjust(by: -30, now: t0)
        XCTAssertEqual(makeStore().period?.alertSeconds, 150, "survives a relaunch")
        store.end()
        XCTAssertNil(store.period)
        XCTAssertNil(alerts.pending)
        XCTAssertNil(makeStore().period)
    }

    func testDisabledAlertStillCounts() {
        settings.enabled = false
        let store = makeStore()
        store.sync(sessionID: session, lastSetAt: t0, now: t0)
        XCTAssertNotNil(store.visiblePeriod(for: session))
        XCTAssertNil(alerts.pending)
    }

    func testOtherSessionIsNotShown() {
        let store = makeStore()
        store.sync(sessionID: session, lastSetAt: t0, now: t0)
        XCTAssertNil(store.visiblePeriod(for: UUID()))
    }
}
