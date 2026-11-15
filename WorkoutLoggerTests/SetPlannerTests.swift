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

    func testPrefillPrefersSessionThenHistory() {
        let session = [SetValues(weight: 80, reps: 8), SetValues(weight: 82.5, reps: 6, rir: 1)]
        let history = [SetValues(weight: 70, reps: 10)]
        XCTAssertEqual(SetPlanner.prefill(sessionSets: session, historySets: history),
                       SetValues(weight: 82.5, reps: 6, rir: nil))
        XCTAssertEqual(SetPlanner.prefill(sessionSets: [], historySets: history),
                       SetValues(weight: 70, reps: 10))
        XCTAssertNil(SetPlanner.prefill(sessionSets: [], historySets: []))
    }

    func testMatchingLast() {
        let last = [SetValues(weight: 80, reps: 8), SetValues(weight: 80, reps: 7)]
        XCTAssertEqual(SetPlanner.matchingLast(index: 1, in: last)?.reps, 7)
        XCTAssertNil(SetPlanner.matchingLast(index: 2, in: last))
    }

    func testWeightStep() {
        XCTAssertEqual(SetPlanner.step(weight: 80, by: 2.5, up: true), 82.5)
        XCTAssertEqual(SetPlanner.step(weight: 0.1 + 0.2, by: 0.1, up: true), 0.4)
        XCTAssertEqual(SetPlanner.step(weight: 1, by: 2, up: false), 0)
    }

    func testWeightFormatter() {
        XCTAssertEqual(WeightFormatter.compact(weight: 80, reps: 8), "80×8")
        XCTAssertEqual(WeightFormatter.compact(weight: 82.5, reps: 6), "82.5×6")
        XCTAssertEqual(WeightFormatter.string(1000), "1000")
    }
}
