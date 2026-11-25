import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class ExerciseLibraryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
    }

    func testCreateAndEditViaEditor() throws {
        let vm = ExerciseEditorViewModel()
        vm.draft = ExerciseDraft(name: " Cable Row ", equipment: .cable, incrementText: "5")
        XCTAssertTrue(vm.save(in: context))
        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<Exercise>()).first)
        XCTAssertEqual(saved.name, "Cable Row")
        XCTAssertEqual(saved.equipment, .cable)
        XCTAssertEqual(saved.weightIncrement, 5)
        XCTAssertFalse(saved.isArchived)

        let edit = ExerciseEditorViewModel(exercise: saved)
        XCTAssertEqual(edit.draft.incrementText, "5")
        edit.draft.name = "Seated Cable Row"
        XCTAssertTrue(edit.save(in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 1)
        XCTAssertEqual(saved.name, "Seated Cable Row")
    }

    func testEditorRejectsDuplicateNameButAllowsKeepingOwnName() throws {
        let existing = Exercise(name: "Bench Press", equipment: .barbell)
        let archived = Exercise(name: "Old Row", equipment: .machine, isArchived: true)
        context.insert(existing)
        context.insert(archived)
        try context.save()

        let vm = ExerciseEditorViewModel()
        vm.draft = ExerciseDraft(name: "bench press ", incrementText: "2.5")
        XCTAssertFalse(vm.save(in: context))
        vm.draft.name = "old row"
        XCTAssertFalse(vm.save(in: context), "archived names count too")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 2)

        let edit = ExerciseEditorViewModel(exercise: existing)
        edit.draft.name = "BENCH PRESS"
        XCTAssertTrue(edit.save(in: context), "an exercise doesn't clash with itself")
    }

    func testInvalidDraftIsNotSaved() throws {
        let vm = ExerciseEditorViewModel()
        vm.draft.name = ""
        XCTAssertFalse(vm.save(in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 0)
    }

    func testDeleteWithoutHistoryRemovesExerciseAndTemplateItems() throws {
        let ex = Exercise(name: "Curl", equipment: .dumbbell)
        context.insert(ex)
        let template = WorkoutTemplate(name: "Arms")
        context.insert(template)
        template.items.append(TemplateExercise(order: 0, exercise: ex))
        try context.save()

        XCTAssertTrue(ExerciseLibraryViewModel().delete(ex, in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TemplateExercise>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()), 1)
    }

    func testExerciseWithHistoryCannotBeDeletedButCanBeArchived() throws {
        let ex = Exercise(name: "Squat", equipment: .barbell)
        context.insert(ex)
        let session = WorkoutSession()
        context.insert(session)
        let entry = SessionExercise(order: 0, exercise: ex)
        session.entries.append(entry)
        entry.sets.append(WorkoutSet(order: 0, weight: 100, reps: 5))
        try context.save()

        let vm = ExerciseLibraryViewModel()
        XCTAssertTrue(ex.hasHistory)
        XCTAssertFalse(vm.delete(ex, in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 1)

        vm.setArchived(true, for: ex, in: context)
        XCTAssertTrue(ex.isArchived)
        XCTAssertTrue(vm.visibleActive([ex]).isEmpty)
        XCTAssertEqual(vm.visibleArchived([ex]).count, 1, "own section at the bottom")
        vm.searchText = "squat"
        XCTAssertTrue(vm.visibleArchived([ex]).isEmpty, "search hides archived")
        XCTAssertEqual(entry.orderedSets.count, 1, "history kept")

        vm.setArchived(false, for: ex, in: context)
        XCTAssertEqual(vm.visibleActive([ex]).count, 1)
    }
}
