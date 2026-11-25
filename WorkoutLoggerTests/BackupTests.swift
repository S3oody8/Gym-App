import SwiftData
import XCTest
@testable import WorkoutLogger

@MainActor
final class BackupTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_760_000_000) // whole seconds

    /// Container with 3 exercises (1 archived), 2 finished sessions, 1 active, 1 template.
    private func makeSource() throws -> ModelContainer {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let store = WorkoutStore(context: context)
        let bench = Exercise(name: "Bench, Flat \"BB\"", equipment: .barbell, weightIncrement: 2.5, createdAt: t0)
        let row = Exercise(name: "Row", equipment: .cable, weightIncrement: 5, createdAt: t0)
        let old = Exercise(name: "Old", equipment: .machine, createdAt: t0, isArchived: true)
        [bench, row, old].forEach(context.insert)

        let s1 = try store.startSession(at: t0)
        try store.rename(s1, to: "Anterior")
        let e1 = try store.addEntry(bench, to: s1)
        try store.addSet(SetValues(weight: 80, reps: 8, rir: 2), to: e1, at: t0.addingTimeInterval(60))
        try store.addSet(SetValues(weight: 60, reps: 12, type: .drop), to: e1, at: t0.addingTimeInterval(240))
        let e2 = try store.addEntry(old, to: s1)
        try store.addSet(SetValues(weight: 50, reps: 10), to: e2, at: t0.addingTimeInterval(600))
        try store.finish(s1)

        let s2 = try store.startSession(at: t0.addingTimeInterval(86_400))
        let e3 = try store.addEntry(row, to: s2)
        try store.addSet(SetValues(weight: 65, reps: 10), to: e3, at: t0.addingTimeInterval(86_460))
        try store.finish(s2)

        // Fixed date: backups keep milliseconds, so a sub-ms "now" could round differently.
        try store.saveTemplate(from: s1, name: "Anterior").createdAt = t0
        let live = try store.startSession(at: t0.addingTimeInterval(2 * 86_400))
        try store.addEntry(row, to: live)
        return container
    }

    private func encoded(_ container: ModelContainer) throws -> String {
        let file = try BackupService(context: container.mainContext).makeBackup(now: t0)
        return String(decoding: try BackupCodec.encode(file), as: UTF8.self)
    }

    private func counts(_ c: ModelContainer) throws -> [Int] {
        let ctx = ModelContext(c)
        return [try ctx.fetchCount(FetchDescriptor<Exercise>()), try ctx.fetchCount(FetchDescriptor<WorkoutSession>()),
                try ctx.fetchCount(FetchDescriptor<SessionExercise>()), try ctx.fetchCount(FetchDescriptor<WorkoutSet>()),
                try ctx.fetchCount(FetchDescriptor<WorkoutTemplate>()), try ctx.fetchCount(FetchDescriptor<TemplateExercise>())]
    }

    func testRoundTripIntoEmptyStoreIsIdentical() throws {
        let source = try makeSource()
        let data = try BackupCodec.encode(try BackupService(context: source.mainContext).makeBackup(now: t0))
        let target = try ModelSchema.makeContainer(inMemory: true)

        let summary = try BackupService(context: target.mainContext).importBackup(try BackupCodec.decode(data))
        XCTAssertEqual(summary, ImportSummary(addedExercises: 3, addedSessions: 3, addedTemplates: 1, skipped: 0))
        XCTAssertEqual(try encoded(target), try encoded(source), "every id, name, set, RIR, type, date and template survives")
        XCTAssertEqual(try counts(target), [3, 3, 4, 4, 1, 2])
    }

    func testImportingTwiceCreatesNoDuplicates() throws {
        let source = try makeSource()
        let file = try BackupCodec.decode(try BackupCodec.encode(try BackupService(context: source.mainContext).makeBackup()))
        let target = try ModelSchema.makeContainer(inMemory: true)
        _ = try BackupService(context: target.mainContext).importBackup(file)
        let second = try BackupService(context: target.mainContext).importBackup(file)
        XCTAssertEqual(second, ImportSummary(skipped: 7))
        XCTAssertEqual(try counts(target), [3, 3, 4, 4, 1, 2])

        let intoSelf = try BackupService(context: source.mainContext).importBackup(file)
        XCTAssertEqual(intoSelf.addedSessions + intoSelf.addedExercises + intoSelf.addedTemplates, 0)
        XCTAssertEqual(try counts(source), [3, 3, 4, 4, 1, 2])
    }

    func testImportNeverOverwritesExistingRecords() throws {
        let source = try makeSource()
        let file = try BackupService(context: source.mainContext).makeBackup()
        let ctx = source.mainContext
        let row = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Row" })
        row.name = "Seated Row"
        let set = try XCTUnwrap(try ctx.fetch(FetchDescriptor<WorkoutSet>()).first { $0.weight == 65 })
        set.weight = 70
        try ctx.save()

        _ = try BackupService(context: ctx).importBackup(file)
        let fresh = ModelContext(source)
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<Exercise>()).map(\.name).sorted(),
                       ["Bench, Flat \"BB\"", "Old", "Seated Row"])
        XCTAssertTrue(try fresh.fetch(FetchDescriptor<WorkoutSet>()).contains { $0.weight == 70 })
        XCTAssertFalse(try fresh.fetch(FetchDescriptor<WorkoutSet>()).contains { $0.weight == 65 })
    }

    func testSameNameDifferentIDMapsToExistingExercise() throws {
        let source = try makeSource()
        let file = try BackupService(context: source.mainContext).makeBackup()
        let target = try ModelSchema.makeContainer(inMemory: true)
        let mine = Exercise(name: " row ", equipment: .machine)
        target.mainContext.insert(mine)
        try target.mainContext.save()

        let summary = try BackupService(context: target.mainContext).importBackup(file)
        XCTAssertEqual(summary.addedExercises, 2)
        let exercises = try target.mainContext.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(exercises.count, 3, "no duplicate 'Row'")
        XCTAssertEqual(mine.sessionEntries.count, 2, "imported Row entries attach to the existing Row")
    }

    func testImportedLiveWorkoutIsClosedWhenOneIsAlreadyActive() throws {
        let source = try makeSource()
        let file = try BackupService(context: source.mainContext).makeBackup()
        let target = try ModelSchema.makeContainer(inMemory: true)
        let mine = try WorkoutStore(context: target.mainContext).startSession()
        _ = try BackupService(context: target.mainContext).importBackup(file)
        let active = try target.mainContext.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.finishedAt == nil }))
        XCTAssertEqual(active.map(\.id), [mine.id])
    }

    func testDecodeRejectsBadFilesAndNewerVersions() throws {
        XCTAssertThrowsError(try BackupCodec.decode(Data("not json".utf8))) {
            XCTAssertEqual($0 as? BackupCodec.DecodeError, .invalidFile)
        }
        var file = BackupFile(exportedAt: t0, exercises: [], sessions: [], templates: [])
        file.version = 99
        XCTAssertThrowsError(try BackupCodec.decode(try BackupCodec.encode(file))) {
            XCTAssertEqual($0 as? BackupCodec.DecodeError, .unsupportedVersion(99))
        }
    }

    func testCSVRowsAndEscaping() throws {
        let source = try makeSource()
        let rows = try BackupService(context: source.mainContext).csvRows()
        XCTAssertEqual(rows.count, 4)
        let utc = TimeZone(identifier: "UTC")!
        let csv = CSVExporter.csv(rows, timeZone: utc)
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines[0], "date,session,exercise,set,type,weight_kg,reps,rir")
        XCTAssertEqual(lines[1], "2025-10-09 08:53,Anterior,\"Bench, Flat \"\"BB\"\"\",1,Working,80,8,2")
        XCTAssertEqual(lines[2], "2025-10-09 08:53,Anterior,\"Bench, Flat \"\"BB\"\"\",2,Drop,60,12,")
        XCTAssertEqual(lines[3], "2025-10-09 08:53,Anterior,Old,1,Working,50,10,")
        XCTAssertEqual(lines[4], "2025-10-10 08:53,,Row,1,Working,65,10,")
    }

    func testAutoBackupDueAfterSevenDays() {
        let last = t0
        XCTAssertTrue(AutoBackupPlan.isDue(lastBackup: nil, now: t0), "never backed up")
        XCTAssertFalse(AutoBackupPlan.isDue(lastBackup: last, now: t0.addingTimeInterval(6 * 86_400 + 86_399)))
        XCTAssertTrue(AutoBackupPlan.isDue(lastBackup: last, now: t0.addingTimeInterval(7 * 86_400)))
        XCTAssertTrue(AutoBackupPlan.isDue(lastBackup: last, now: t0.addingTimeInterval(30 * 86_400)))
    }

    func testAutoBackupFileNameAndPruning() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let date = utc.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 9))!
        XCTAssertEqual(AutoBackupPlan.fileName(for: date, calendar: utc), "WorkoutLogger-backup-2026-11-03.json")

        let backups = (1...10).map { String(format: "WorkoutLogger-backup-2026-%02d-01.json", $0) }
        let others = ["notes.txt", "WorkoutLogger-backup-export.json", "WorkoutLogger-sets-2026-01-01.csv"]
        let pruned = AutoBackupPlan.filesToPrune((backups + others).shuffled())
        XCTAssertEqual(Set(pruned), ["WorkoutLogger-backup-2026-01-01.json", "WorkoutLogger-backup-2026-02-01.json"],
                       "keeps the newest 8, never touches other files")
        XCTAssertTrue(AutoBackupPlan.filesToPrune(Array(backups.prefix(8))).isEmpty)
    }

    func testAutoBackupWritesAndPrunesFolder() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "AutoBackupTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for month in 1...8 {
            try Data("{}".utf8).write(to: folder.appending(path: String(format: "WorkoutLogger-backup-2026-%02d-01.json", month)))
        }
        try Data("keep".utf8).write(to: folder.appending(path: "notes.txt"))
        try AutoBackup.write(Data("{\"v\":1}".utf8), named: "WorkoutLogger-backup-2026-11-25.json", in: folder)
        let names = try FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false)).sorted()
        XCTAssertEqual(names.count, 9)
        XCTAssertFalse(names.contains("WorkoutLogger-backup-2026-01-01.json"), "oldest pruned")
        XCTAssertTrue(names.contains("notes.txt"))
        XCTAssertTrue(names.contains("WorkoutLogger-backup-2026-11-25.json"))
    }
}
