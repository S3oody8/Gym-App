import XCTest
@testable import WorkoutLogger

final class ExerciseSearchTests: XCTestCase {
    private struct Item { let name: String; let archived: Bool }

    func testMatchesIsCaseAndDiacriticInsensitive() {
        XCTAssertTrue(ExerciseSearch.matches(name: "Lat Pulldown – Neutral", query: "pulldown"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Café Curl", query: "cafe"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Row", query: "   "))
        XCTAssertFalse(ExerciseSearch.matches(name: "Row", query: "press"))
    }

    func testFilterHidesArchivedAndSorts() {
        let items = [Item(name: "b Row", archived: false),
                     Item(name: "A Press", archived: false),
                     Item(name: "Old Row", archived: true)]
        let result = ExerciseSearch.filter(items, query: "", name: \.name, isArchived: \.archived)
        XCTAssertEqual(result.map(\.name), ["A Press", "b Row"])
        let searched = ExerciseSearch.filter(items, query: "row", name: \.name, isArchived: \.archived)
        XCTAssertEqual(searched.map(\.name), ["b Row"])
        let all = ExerciseSearch.filter(items, query: "row", includeArchived: true,
                                        name: \.name, isArchived: \.archived)
        XCTAssertEqual(all.map(\.name), ["b Row", "Old Row"])
    }
}
