import SwiftData
import XCTest
@testable import WorkoutLogger

final class SessionMetricsTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func testLoadSumsWorkingAndDropSets() {
        let sets = [SetValues(weight: 80, reps: 8), SetValues(weight: 82.5, reps: 6),
                    SetValues(weight: 60, reps: 12, type: .drop), SetValues(weight: 0, reps: 10)]
        XCTAssertEqual(SessionMetrics.load(sets), 640 + 495 + 720)
        XCTAssertEqual(SessionMetrics.load([]), 0)
    }

    func testLoadText() {
        XCTAssertEqual(SessionMetrics.loadText(4820), "Load 4,820 kg")
        XCTAssertEqual(SessionMetrics.loadText(812.5), "Load 813 kg")
        XCTAssertEqual(SessionMetrics.loadText(0), "Load 0 kg")
    }

    func testShortDateShowsYearOnlyWhenNotCurrent() {
        let now = date(2026, 11, 15)
        XCTAssertEqual(SessionMetrics.shortDate(date(2026, 11, 15), now: now, calendar: calendar), "15/11")
        XCTAssertEqual(SessionMetrics.shortDate(date(2026, 3, 5), now: now, calendar: calendar), "05/03")
        XCTAssertEqual(SessionMetrics.shortDate(date(2025, 12, 31), now: now, calendar: calendar), "31/12/2025")
    }

    func testTitles() {
        let now = date(2026, 11, 15)
        XCTAssertEqual(SessionMetrics.title(name: " Anterior "), "Anterior")
        XCTAssertEqual(SessionMetrics.title(name: "  "), "Workout")
        XCTAssertEqual(SessionMetrics.detailTitle(name: "Anterior", date: now, now: now, calendar: calendar),
                       "15/11 – Anterior")
        XCTAssertEqual(SessionMetrics.detailTitle(name: "", date: now, now: now, calendar: calendar), "15/11")
    }
}

@MainActor
final class SessionNameTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var store: WorkoutStore { WorkoutStore(context: context) }
    private var bench: Exercise!

    override func setUp() async throws {
        container = try ModelSchema.makeContainer(inMemory: true)
        bench = Exercise(name: "Bench", equipment: .barbell)
        context.insert(bench)
        try context.save()
    }

    private func persistedSession() throws -> WorkoutSession? {
        try ModelContext(container).fetch(FetchDescriptor<WorkoutSession>()).first
    }

    func testStartFromTemplatePrefillsName() throws {
        let template = WorkoutTemplate(name: "Anterior")
        context.insert(template)
        template.items.append(TemplateExercise(order: 0, exercise: bench))
        let session = try store.startSession(from: template)
        XCTAssertEqual(session.name, "Anterior")
        XCTAssertEqual(try persistedSession()?.name, "Anterior")
    }

    func testRenameIsSavedAsTyped() throws {
        let session = try store.startSession()
        let vm = SessionEditorViewModel(session: session, context: context, restAlerts: FakeRestAlerts())
        XCTAssertTrue(vm.needsNameBeforeFinish)
        vm.rename(to: "Upper ")
        XCTAssertEqual(try persistedSession()?.name, "Upper ", "kept as typed so spaces can be entered")
        vm.rename(to: "Upper Body")
        XCTAssertFalse(vm.needsNameBeforeFinish)
    }

    func testFinishWithNameOrSkip() throws {
        let named = try store.startSession()
        let vm = SessionEditorViewModel(session: named, context: context, restAlerts: FakeRestAlerts())
        vm.addExercise(bench)
        vm.quickAdd(to: named.orderedEntries[0], minus: 1)
        vm.finish(naming: "  Posterior ")
        XCTAssertEqual(named.name, "Posterior")
        XCTAssertFalse(named.isActive)

        let skipped = try store.startSession()
        let vm2 = SessionEditorViewModel(session: skipped, context: context, restAlerts: FakeRestAlerts())
        vm2.finish()
        XCTAssertEqual(skipped.name, "")
        XCTAssertFalse(skipped.isActive)
    }

    func testDeleteAndUndoKeepsName() throws {
        let session = try store.startSession()
        try store.rename(session, to: "Anterior")
        let entry = try store.addEntry(bench, to: session)
        try store.addSet(SetValues(weight: 80, reps: 8), to: entry)
        try store.finish(session)
        XCTAssertEqual(session.load, 640)
        let snapshot = try store.deleteSession(session)
        let restored = try store.restoreSession(snapshot)
        XCTAssertEqual(restored.name, "Anterior")
        XCTAssertEqual(restored.load, 640)
    }
}
