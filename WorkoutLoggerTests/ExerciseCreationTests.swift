import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class ExerciseCreationTests: XCTestCase {
    func testNameNormalisation() {
        XCTAssertEqual(ExerciseCreation.name(from: "  incline smith press "), "Incline Smith Press")
        XCTAssertEqual(ExerciseCreation.name(from: "lat   pulldown – neutral"), "Lat Pulldown – Neutral")
        XCTAssertEqual(ExerciseCreation.name(from: "RDL"), "RDL")
        XCTAssertEqual(ExerciseCreation.name(from: "élévation"), "Élévation")
        XCTAssertNil(ExerciseCreation.name(from: "   "))
    }

    func testRowHiddenOnExactMatch() {
        let names = ["Lat Pulldown – Neutral", "Bench Press"]
        XCTAssertNil(ExerciseCreation.offeredName(for: " bench press ", among: names))
        XCTAssertNil(ExerciseCreation.offeredName(for: "BENCH PRESS", among: names))
        XCTAssertNil(ExerciseCreation.offeredName(for: "", among: names))
        XCTAssertEqual(ExerciseCreation.offeredName(for: "bench", among: names), "Bench")
        XCTAssertEqual(ExerciseCreation.offeredName(for: "neutral lat", among: names), "Neutral Lat")
    }

    func testCreateAddsExerciseAndOpensSetPad() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let store = WorkoutStore(context: context)
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())

        let created = try store.createExercise(named: "Incline Smith Press")
        let entryID = try XCTUnwrap(vm.addExercise(created))
        vm.openAddSet(forEntryID: entryID)

        XCTAssertEqual(vm.entryRequest?.entryID, entryID)
        XCTAssertEqual(vm.entryRequest?.exerciseName, "Incline Smith Press")
        XCTAssertEqual(try ModelContext(container).fetchCount(FetchDescriptor<Exercise>()), 1)
    }

    func testCreateRejectsDuplicateIncludingArchived() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        context.insert(Exercise(name: "Old Row", equipment: .cable, isArchived: true))
        try context.save()
        let store = WorkoutStore(context: context)
        XCTAssertThrowsError(try store.createExercise(named: " old row ")) {
            XCTAssertEqual($0 as? ExerciseDraft.ValidationError, .duplicateName)
        }
        XCTAssertThrowsError(try store.createExercise(named: "  "))
    }
}
