import SwiftData
import XCTest
@testable import WorkoutLogger

final class QuickButtonsTests: XCTestCase {
    func testParsing() {
        XCTAssertNil(QuickButtons.parse(""))
        XCTAssertNil(QuickButtons.parse("   "))
        XCTAssertNil(QuickButtons.parse("0"))
        XCTAssertNil(QuickButtons.parse("10"))
        XCTAssertNil(QuickButtons.parse("x"))
        XCTAssertEqual(QuickButtons.parse("2"), 2)
        XCTAssertEqual(QuickButtons.parse("−2"), 2)
        XCTAssertEqual(QuickButtons.parse("-2"), 2)
        XCTAssertEqual(QuickButtons.parse(" 9 "), 9)
    }

    func testEmptySlotHidesButton() {
        XCTAssertEqual(QuickButtons.values(from: ["1", "", "3"]), [1, 3])
        XCTAssertEqual(QuickButtons.values(from: ["", "", ""]), [])
        XCTAssertEqual(QuickButtons.label(2), "−2")
    }

    func testSanitizeKeepsOneDigit() {
        XCTAssertEqual(QuickButtons.sanitize("12"), "2")
        XCTAssertEqual(QuickButtons.sanitize("0"), "")
        XCTAssertEqual(QuickButtons.sanitize("−4"), "4")
        XCTAssertEqual(QuickButtons.sanitize(""), "")
    }

    func testDefaultsAndStoredValues() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "QuickButtonsTests"))
        defaults.removePersistentDomain(forName: "QuickButtonsTests")
        XCTAssertEqual(QuickButtons.current(from: defaults), [1, 2, 3])
        defaults.set("", forKey: QuickButtons.keys[1])
        defaults.set("5", forKey: QuickButtons.keys[2])
        XCTAssertEqual(QuickButtons.current(from: defaults), [1, 5])
        defaults.removePersistentDomain(forName: "QuickButtonsTests")
    }
}

@MainActor
final class CurrentExerciseTests: XCTestCase {
    func testCurrentIsTheExerciseWithTheMostRecentSet() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let bench = Exercise(name: "Bench", equipment: .barbell)
        let row = Exercise(name: "Row", equipment: .cable)
        [bench, row].forEach(context.insert)
        let session = try WorkoutStore(context: context).startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts(),
                                        quickButtons: { [2, 4] })
        vm.addExercise(bench)
        vm.addExercise(row)
        let (b, r) = (session.orderedEntries[0], session.orderedEntries[1])
        XCTAssertFalse(vm.isCurrent(b) || vm.isCurrent(r), "no sets yet: no current exercise")

        vm.submit(SetValues(weight: 80, reps: 8),
                  for: SetEntryRequest(entryID: b.id, setID: nil, exerciseName: "Bench", initial: nil))
        XCTAssertTrue(vm.isCurrent(b))
        try WorkoutStore(context: context).addSet(SetValues(weight: 60, reps: 10), to: r, at: .now.addingTimeInterval(1))
        XCTAssertTrue(vm.isCurrent(r))
        XCTAssertFalse(vm.isCurrent(b))

        XCTAssertEqual(vm.quickButtons, [2, 4])
        vm.quickAdd(to: r, minus: 4)
        XCTAssertEqual(r.orderedSets.last?.values.reps, 6)
    }
}
