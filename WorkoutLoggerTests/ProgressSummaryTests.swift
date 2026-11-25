import SwiftData
import XCTest
@testable import WorkoutLogger

final class ProgressSummaryTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    private func day(_ n: Int) -> Date { t0.addingTimeInterval(Double(n) * 86_400) }

    func testExerciseOrderingRecentFirstThenName() {
        struct Item { let name: String; let used: Date? }
        let items = [Item(name: "Curl", used: nil), Item(name: "Row", used: day(1)),
                     Item(name: "bench", used: day(3)), Item(name: "Apple", used: nil),
                     Item(name: "Squat", used: day(1))]
        let sorted = ExerciseOrdering.recentFirst(items, lastUsed: \.used, name: \.name)
        XCTAssertEqual(sorted.map(\.name), ["bench", "Row", "Squat", "Apple", "Curl"])
    }

    func testChange() {
        XCTAssertNil(ProgressSummary.change([ProgressPoint(date: day(0), value: 100)]))
        XCTAssertEqual(ProgressSummary.change([ProgressPoint(date: day(0), value: 100),
                                               ProgressPoint(date: day(5), value: 104.5)]), 4.5)
        XCTAssertEqual(ProgressSummary.changeLabel(4.5, metric: .topSet), "+4.5 kg")
        XCTAssertEqual(ProgressSummary.changeLabel(-120, metric: .volume), "−120 kg")
        XCTAssertEqual(ProgressSummary.changeLabel(0, metric: .e1RM), "±0 kg")
    }

    func testBestSetPerMetric() {
        let sessions = [
            ProgressSessionInput(date: day(0), sets: [SetValues(weight: 80, reps: 10), SetValues(weight: 90, reps: 3)]),
            ProgressSessionInput(date: day(7), sets: [SetValues(weight: 82.5, reps: 8),
                                                      SetValues(weight: 40, reps: 30, type: .drop)]),
        ]
        let now = day(8)
        // e1RM: 80×10 → 106.7, 90×3 → 99, 82.5×8 → 104.5
        XCTAssertEqual(ProgressSummary.bestSet(.e1RM, sessions: sessions, range: .all, now: now),
                       BestSet(values: SetValues(weight: 80, reps: 10), date: day(0)))
        XCTAssertEqual(ProgressSummary.bestSet(.topSet, sessions: sessions, range: .all, now: now)?.values.weight, 90)
        XCTAssertEqual(ProgressSummary.bestSet(.volume, sessions: sessions, range: .all, now: now)?.values,
                       SetValues(weight: 40, reps: 30, type: .drop), "volume counts drop sets")
        XCTAssertNil(ProgressSummary.bestSet(.e1RM, sessions: [], range: .all, now: now))
        XCTAssertEqual(WeightFormatter.spaced(weight: 82.5, reps: 8), "82.5 × 8")
    }

    func testRecentPRsNewestFirst() {
        let s1 = UUID(), s2 = UUID(), s3 = UUID()
        func set(_ session: UUID, _ d: Int, _ order: Int, _ w: Double, _ r: Int) -> PRInputSet {
            PRInputSet(id: UUID(), sessionID: session, sessionStart: day(d), order: order,
                       values: SetValues(weight: w, reps: r))
        }
        let bench = [set(s1, 0, 0, 80, 8), set(s2, 7, 0, 82.5, 8), set(s3, 14, 0, 82.5, 9)]
        let row = [set(s1, 0, 0, 60, 10), set(s2, 7, 0, 55, 10)]
        let prs = ProgressSummary.recentPRs([("Bench", bench), ("Row", row)])
        XCTAssertEqual(prs.map(\.exerciseName), ["Bench", "Bench"])
        XCTAssertEqual(prs.map(\.date), [day(14), day(7)])
        XCTAssertEqual(prs.first?.values, SetValues(weight: 82.5, reps: 9))
        XCTAssertEqual(ProgressSummary.recentPRs([("Bench", bench)], limit: 1).count, 1)
    }

    @MainActor
    func testExerciseLastUsedIgnoresEntriesWithoutSets() throws {
        let container = try ModelSchema.makeContainer(inMemory: true)
        let context = container.mainContext
        let bench = Exercise(name: "Bench", equipment: .barbell)
        context.insert(bench)
        let store = WorkoutStore(context: context)
        XCTAssertNil(bench.lastUsed)
        let old = try store.startSession(at: day(0))
        try store.addSet(SetValues(weight: 80, reps: 8), to: try store.addEntry(bench, to: old), at: day(0))
        let empty = try store.startSession(at: day(5))
        try store.addEntry(bench, to: empty)
        XCTAssertEqual(bench.lastUsed, day(0))
    }
}
