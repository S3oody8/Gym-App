import XCTest
@testable import WorkoutLogger

final class SetPlannerTests: XCTestCase {
    func testQuickSetReducesRepsWithMinimumOne() {
        let prev = SetValues(weight: 80, reps: 8, rir: 2, type: .drop)
        XCTAssertEqual(SetPlanner.quickSet(from: prev, minus: 1), SetValues(weight: 80, reps: 7, rir: nil))
        XCTAssertEqual(SetPlanner.quickSet(from: prev, minus: 3).reps, 5)
        XCTAssertEqual(SetPlanner.quickSet(from: SetValues(weight: 50, reps: 2), minus: 3).reps, 1)
        XCTAssertEqual(SetPlanner.quickSet(from: SetValues(weight: 50, reps: 1), minus: 1).reps, 1)
    }

    func testPrefillFirstSetUsesSetOneOfPreviousSessionWithRepsHint() {
        let previous = [SetValues(weight: 70, reps: 10), SetValues(weight: 75, reps: 8)]
        XCTAssertEqual(SetPlanner.prefill(sessionSets: [], previousSessionSets: previous),
                       SetPrefill(weight: 70, repsHint: 10, field: .reps))
    }

    func testPrefillLaterSetsUsePreviousWeightOnly() {
        let session = [SetValues(weight: 80, reps: 8), SetValues(weight: 82.5, reps: 6, rir: 1)]
        let previous = [SetValues(weight: 70, reps: 10)]
        XCTAssertEqual(SetPlanner.prefill(sessionSets: session, previousSessionSets: previous),
                       SetPrefill(weight: 82.5, repsHint: nil, field: .reps))
    }

    func testPrefillNeverDoneIsEmptyWithCursorInWeight() {
        XCTAssertEqual(SetPlanner.prefill(sessionSets: [], previousSessionSets: []),
                       SetPrefill(weight: nil, repsHint: nil, field: .weight))
    }

    func testDoubleRoundsToHundredths() {
        XCTAssertEqual(SetPlanner.doubled(22.5), 45)
        XCTAssertEqual(SetPlanner.doubled(12.345), 24.69)
        XCTAssertEqual(SetPlanner.doubled(0.1 + 0.2), 0.6)
        XCTAssertEqual(SetPlanner.doubled(33.335), 66.67)
    }

    func testWeightFormatter() {
        XCTAssertEqual(WeightFormatter.compact(weight: 80, reps: 8), "80×8")
        XCTAssertEqual(WeightFormatter.compact(weight: 82.5, reps: 6), "82.5×6")
        XCTAssertEqual(WeightFormatter.string(1000), "1000")
    }
}
