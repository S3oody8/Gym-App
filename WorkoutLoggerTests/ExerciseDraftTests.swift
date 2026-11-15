import XCTest
@testable import WorkoutLogger

final class ExerciseDraftTests: XCTestCase {
    func testValidation() {
        var draft = ExerciseDraft(name: "  ", incrementText: "2.5")
        XCTAssertEqual(draft.validate(), .emptyName)
        draft.name = " Bench "
        XCTAssertNil(draft.validate())
        XCTAssertEqual(draft.trimmedName, "Bench")
        for bad in ["", "0", "-1", "abc"] {
            draft.incrementText = bad
            XCTAssertEqual(draft.validate(), .invalidIncrement, bad)
        }
    }

    func testDuplicateNamesAreBlockedCaseInsensitiveAndTrimmed() {
        let draft = ExerciseDraft(name: "  bench press ", incrementText: "2.5")
        XCTAssertEqual(draft.validate(existingNames: ["Bench Press"]), .duplicateName)
        XCTAssertEqual(draft.validate(existingNames: [" BENCH PRESS"]), .duplicateName)
        XCTAssertNil(draft.validate(existingNames: ["Bench Press – Incline"]))
        XCTAssertNil(draft.validate(existingNames: []))
    }

    func testIncrementAcceptsCommaDecimal() {
        XCTAssertEqual(ExerciseDraft(incrementText: "1,25").increment, 1.25)
        XCTAssertEqual(ExerciseDraft(incrementText: "5").increment, 5)
    }

    func testCleanedSecondaryDropsPrimaryAndKeepsEnumOrder() {
        let draft = ExerciseDraft(primary: .chest, secondary: [.triceps, .chest, .frontDelts])
        XCTAssertEqual(draft.cleanedSecondary, [.frontDelts, .triceps])
    }

    func testFormat() {
        XCTAssertEqual(ExerciseDraft.format(2.5), "2.5")
        XCTAssertEqual(ExerciseDraft.format(5), "5")
        XCTAssertEqual(ExerciseDraft.format(1.25), "1.25")
    }

    func testMuscleRawValuesAreStable() {
        XCTAssertEqual(MuscleGroup.allCases.map(\.rawValue), [
            "Chest", "Lats", "Upper Back", "Lower Back", "Traps", "Front Delts", "Side Delts",
            "Rear Delts", "Biceps", "Triceps", "Forearms", "Abs", "Quads", "Hamstrings",
            "Glutes", "Adductors", "Calves",
        ])
        XCTAssertEqual(Equipment.allCases.map(\.rawValue),
                       ["Smith", "Machine", "Cable", "Dumbbell", "Barbell", "Bodyweight"])
    }
}
