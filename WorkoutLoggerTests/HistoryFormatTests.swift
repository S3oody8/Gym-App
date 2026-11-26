import XCTest
@testable import WorkoutLogger

final class HistoryFormatTests: XCTestCase {
    private let calendar = CalendarMath.mondayCalendar(timeZone: TimeZone(identifier: "UTC")!)

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testRowLine() {
        let now = date(2026, 11, 25)
        let line = HistoryFormat.rowLine(start: date(2026, 11, 24, 12, 2), duration: 61 * 60 + 20,
                                         sets: 20, volume: 6140.4, now: now, calendar: calendar)
        XCTAssertEqual(line, "Tue 24/11 · 61 min · 20 sets · 6,140 kg")
        let imported = HistoryFormat.rowLine(start: date(2025, 3, 2), duration: 0, sets: 1, volume: 80,
                                             now: now, calendar: calendar)
        XCTAssertEqual(imported, "Sun 02/03/2025 · 1 set · 80 kg", "year only when not current; no 0 min")
    }

    func testPRText() {
        XCTAssertNil(HistoryFormat.prs(0))
        XCTAssertEqual(HistoryFormat.prs(1), "1 PR")
        XCTAssertEqual(HistoryFormat.prs(3), "3 PRs")
    }

    func testDetailLine() {
        let now = date(2026, 11, 25)
        XCTAssertEqual(HistoryFormat.detailLine(start: date(2026, 11, 24, 12, 2), end: date(2026, 11, 24, 13, 3),
                                                now: now, calendar: calendar),
                       "Tue 24/11 · 12:02 – 13:03")
        XCTAssertEqual(HistoryFormat.detailLine(start: date(2026, 11, 24, 9, 5), end: date(2026, 11, 24, 9, 5),
                                                now: now, calendar: calendar), "Tue 24/11")
    }

    func testGroupingThisWeekLastWeekAndMonths() {
        let now = date(2026, 11, 25) // Wednesday
        let dates = [date(2026, 11, 24), date(2026, 11, 23, 8), // this week (Mon 23 – Sun 29)
                     date(2026, 11, 22), date(2026, 11, 16, 8), // last week (Mon 16 – Sun 22)
                     date(2026, 11, 15), date(2026, 11, 2),
                     date(2026, 10, 30), date(2025, 12, 1)]
        let groups = HistoryGrouping.groups(dates, date: { $0 }, now: now, calendar: calendar)
        XCTAssertEqual(groups.map(\.title), ["This week", "Last week", "November 2026", "October 2026", "December 2025"])
        XCTAssertEqual(groups.map(\.items.count), [2, 2, 2, 1, 1])
    }

    func testPRCountsBySession() {
        let s1 = UUID(), s2 = UUID()
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        func set(_ session: UUID, _ day: Double, _ order: Int, _ w: Double, _ r: Int) -> PRInputSet {
            PRInputSet(id: UUID(), sessionID: session, sessionStart: t0.addingTimeInterval(day * 86_400),
                       order: order, values: SetValues(weight: w, reps: r))
        }
        let s0 = UUID()
        let sets = [set(s0, 0, 0, 80, 8),
                    set(s1, 1, 0, 85, 9), set(s1, 1, 1, 70, 12), // weight + reps (counts once), reps
                    set(s2, 2, 0, 90, 3)]                        // weight
        let index = ExercisePRIndex(sets: sets)
        XCTAssertEqual(index.prCountsBySession, [s1: 2, s2: 1], "a set with two badges counts once")
        XCTAssertEqual(index.prSets.count, 3)
        XCTAssertEqual(index.lastUsed, t0.addingTimeInterval(2 * 86_400))
    }
}
