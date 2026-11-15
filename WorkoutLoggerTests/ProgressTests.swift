import SwiftData
import XCTest
@testable import WorkoutLogger

final class ProgressMathTests: XCTestCase {
    func testE1RMEpley() throws {
        XCTAssertEqual(ProgressMath.e1RM(weight: 100, reps: 1), 100)
        XCTAssertEqual(try XCTUnwrap(ProgressMath.e1RM(weight: 100, reps: 10)), 133.333, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(ProgressMath.e1RM(weight: 80, reps: 12)), 112, accuracy: 0.0001)
        XCTAssertNil(ProgressMath.e1RM(weight: 80, reps: 13), "only ≤12 reps")
        XCTAssertNil(ProgressMath.e1RM(weight: 80, reps: 0))
    }

    func testSessionValuesUseRightSetTypes() throws {
        let sets = [SetValues(weight: 80, reps: 8), SetValues(weight: 85, reps: 15),
                    SetValues(weight: 100, reps: 3, type: .drop), SetValues(weight: 60, reps: 12, type: .drop)]
        XCTAssertEqual(try XCTUnwrap(ProgressMath.value(.e1RM, sets: sets)), 80 * (1 + 8.0 / 30), accuracy: 0.0001,
                       "drop sets and >12 reps excluded")
        XCTAssertEqual(ProgressMath.value(.topSet, sets: sets), 85, "working sets only")
        XCTAssertEqual(ProgressMath.value(.volume, sets: sets), 640 + 1275 + 300 + 720, "working + drop")
        XCTAssertNil(ProgressMath.value(.e1RM, sets: [SetValues(weight: 50, reps: 20)]))
        XCTAssertNil(ProgressMath.value(.topSet, sets: [SetValues(weight: 50, reps: 5, type: .drop)]))
        XCTAssertNil(ProgressMath.value(.volume, sets: []))
    }

    func testPointsFilterByRangeAndSort() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let now = cal.date(from: DateComponents(year: 2026, month: 11, day: 15))!
        func daysAgo(_ d: Int) -> Date { now.addingTimeInterval(-Double(d) * 86_400) }
        let sessions = [
            ProgressSessionInput(date: daysAgo(10), sets: [SetValues(weight: 90, reps: 5)]),
            ProgressSessionInput(date: daysAgo(400), sets: [SetValues(weight: 60, reps: 5)]),
            ProgressSessionInput(date: daysAgo(60), sets: [SetValues(weight: 80, reps: 5)]),
            ProgressSessionInput(date: daysAgo(5), sets: [SetValues(weight: 40, reps: 10, type: .drop)]),
        ]
        XCTAssertEqual(ProgressMath.points(.topSet, sessions: sessions, range: .oneMonth, now: now, calendar: cal).map(\.value),
                       [90], "drop-only session has no top set")
        XCTAssertEqual(ProgressMath.points(.topSet, sessions: sessions, range: .threeMonths, now: now, calendar: cal).map(\.value),
                       [80, 90])
        XCTAssertEqual(ProgressMath.points(.topSet, sessions: sessions, range: .all, now: now, calendar: cal).map(\.value),
                       [60, 80, 90])
        XCTAssertEqual(ProgressMath.points(.volume, sessions: sessions, range: .oneMonth, now: now, calendar: cal).map(\.value),
                       [450, 400])
    }

    func testLabels() {
        XCTAssertEqual(ProgressMath.label(106.6667, metric: .e1RM), "106.7 kg")
        XCTAssertEqual(ProgressMath.label(82.5, metric: .topSet), "82.5 kg")
        XCTAssertEqual(ProgressMath.label(4820, metric: .volume), "4,820 kg")
    }
}

final class PRDetectorTests: XCTestCase {
    private let s1 = UUID(), s2 = UUID(), s3 = UUID()
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    private func set(_ session: UUID, day: Int, _ order: Int, _ w: Double, _ r: Int,
                     _ type: SetType = .working, id: UUID = UUID()) -> PRInputSet {
        PRInputSet(id: id, sessionID: session, sessionStart: t0.addingTimeInterval(Double(day) * 86_400),
                   order: order, values: SetValues(weight: w, reps: r, type: type))
    }

    func testFirstSessionHasNoBadges() {
        let sets = [set(s1, day: 0, 0, 80, 8), set(s1, day: 0, 1, 85, 6)]
        XCTAssertTrue(PRDetector.badges(for: sets).isEmpty)
    }

    func testHeaviestWeightPR() {
        let heavy = UUID(), same = UUID()
        let sets = [set(s1, day: 0, 0, 80, 8),
                    set(s2, day: 7, 0, 82.5, 5, id: heavy),
                    set(s2, day: 7, 1, 82.5, 4, id: same)]
        let badges = PRDetector.badges(for: sets)
        XCTAssertEqual(badges[heavy], [.weight], "heavier than all before; no earlier set ≥ 82.5 so no reps PR")
        XCTAssertNil(badges[same], "equal weight isn't a PR, fewer reps than set 1 at ≥ 82.5")
    }

    func testMostRepsAtWeightBeatsEverySetAtOrAboveThatWeight() {
        let repsPR = UUID(), notPR = UUID(), lighter = UUID()
        let sets = [set(s1, day: 0, 0, 80, 8), set(s1, day: 0, 1, 90, 9),
                    set(s2, day: 7, 0, 80, 9, id: notPR),     // 90×9 is at ≥80 with 9 reps → not beaten
                    set(s3, day: 14, 0, 80, 10, id: repsPR),  // beats 80×8, 90×9, 80×9
                    set(s3, day: 14, 1, 70, 10, id: lighter)] // earlier 80×10 at ≥70 → tie, not PR
        let badges = PRDetector.badges(for: sets)
        XCTAssertNil(badges[notPR])
        XCTAssertEqual(badges[repsPR], [.reps])
        XCTAssertNil(badges[lighter])
    }

    func testDropSetsIgnoredAndCanEarnBothBadges() {
        let both = UUID(), drop = UUID()
        let sets = [set(s1, day: 0, 0, 100, 5), set(s1, day: 0, 1, 120, 2, .drop),
                    set(s2, day: 7, 0, 110, 5, .drop, id: drop),
                    set(s2, day: 7, 1, 105, 6, id: both)]
        let badges = PRDetector.badges(for: sets)
        XCTAssertNil(badges[drop], "drop sets never get PRs")
        XCTAssertEqual(badges[both], [.weight], "the 120 drop set doesn't count; nothing earlier ≥105")
    }

    func testOrderWithinSessionMatters() {
        let first = UUID(), second = UUID()
        let sets = [set(s1, day: 0, 0, 80, 8),
                    set(s2, day: 7, 1, 85, 5, id: second),
                    set(s2, day: 7, 0, 82.5, 6, id: first)]
        let badges = PRDetector.badges(for: sets)
        XCTAssertEqual(badges[first], [.weight])
        XCTAssertEqual(badges[second], [.weight], "heavier again later in the same session")
    }
}

final class CalendarMathTests: XCTestCase {
    private let cal = CalendarMath.mondayCalendar(timeZone: TimeZone(identifier: "UTC")!)

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func testMondayFirstGrid() {
        // November 2026 starts on a Sunday → 6 leading blanks in a Monday-first grid.
        let grid = CalendarMath.monthGrid(for: date(2026, 11, 15), calendar: cal)
        XCTAssertEqual(grid.prefix(6).filter { $0 == nil }.count, 6)
        XCTAssertEqual(grid[6], cal.startOfDay(for: date(2026, 11, 1)))
        XCTAssertEqual(grid.compactMap { $0 }.count, 30)
        // June 2026 starts on a Monday → no blanks.
        XCTAssertEqual(CalendarMath.monthGrid(for: date(2026, 6, 10), calendar: cal).first!, cal.startOfDay(for: date(2026, 6, 1)))
    }

    func testWeekdaySymbolsStartMonday() {
        XCTAssertEqual(CalendarMath.weekdaySymbols(calendar: cal).count, 7)
        XCTAssertEqual(CalendarMath.weekdaySymbols(calendar: cal).first, cal.veryShortStandaloneWeekdaySymbols[1])
    }

    func testSessionsGroupedByDay() {
        let dates = [date(2026, 11, 2, 7), date(2026, 11, 2, 19), date(2026, 11, 4)]
        let grouped = CalendarMath.sessionsByDay(dates, date: { $0 }, calendar: cal)
        XCTAssertEqual(grouped[cal.startOfDay(for: date(2026, 11, 2))]?.count, 2)
        XCTAssertEqual(grouped.count, 2)
    }
}

@MainActor
final class ProgressIntegrationTests: XCTestCase {
    func testBadgesRecomputeAfterEditingAPastSession() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let store = WorkoutStore(context: context)
        let bench = Exercise(name: "Bench", equipment: .barbell)
        context.insert(bench)
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)

        let first = try store.startSession(at: t0)
        let e1 = try store.addEntry(bench, to: first)
        try store.addSet(SetValues(weight: 80, reps: 8), to: e1, at: t0)
        try store.finish(first)
        let second = try store.startSession(at: t0.addingTimeInterval(7 * 86_400))
        let e2 = try store.addEntry(bench, to: second)
        let pr = try store.addSet(SetValues(weight: 85, reps: 5), to: e2, at: t0.addingTimeInterval(7 * 86_400))

        let vm = SessionEditorViewModel(session: second, context: context, restAlerts: FakeRestAlerts())
        XCTAssertEqual(vm.prBadges(for: e2)[pr.id], [.weight])

        // Editing the older session to 90 kg removes the later PR.
        try store.update(e1.orderedSets[0], to: SetValues(weight: 90, reps: 8))
        XCTAssertNil(vm.prBadges(for: e2)[pr.id])

        // Moving the older session after the newer one swaps which session is "first".
        let pastVM = SessionEditorViewModel(session: first, context: context, restAlerts: FakeRestAlerts())
        pastVM.moveStart(to: t0.addingTimeInterval(14 * 86_400))
        XCTAssertEqual(pastVM.prBadges(for: e1)[e1.orderedSets[0].id], [.weight])

        let progress = ExerciseProgressViewModel(exercise: bench, metric: .topSet)
        progress.range = .all
        XCTAssertEqual(progress.points(now: t0.addingTimeInterval(30 * 86_400)).map(\.value), [85, 90])
        XCTAssertEqual(progress.history.map(\.session.id), [first.id, second.id], "newest first")
    }
}
