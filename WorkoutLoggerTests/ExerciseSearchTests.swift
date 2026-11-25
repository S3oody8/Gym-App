import XCTest
@testable import WorkoutLogger

final class ExerciseSearchTests: XCTestCase {
    private struct Item { let name: String; let archived: Bool }

    func testMatchesIsCaseAndDiacriticInsensitive() {
        XCTAssertTrue(ExerciseSearch.matches(name: "Lat Pulldown – Neutral", query: "pulldown"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Lat Pulldown – Neutral", query: "LAT PULL"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Café Curl", query: "cafe"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Cafe Curl", query: "café"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Row", query: "   "))
    }

    func testWordsMatchInAnyOrder() {
        XCTAssertTrue(ExerciseSearch.matches(name: "Lat Pulldown – Neutral", query: "neutral lat"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Incline Smith Press", query: "press  smith incline"))
    }

    func testPartialWordsMatch() {
        XCTAssertTrue(ExerciseSearch.matches(name: "Lat Pulldown – Neutral", query: "neu pull"))
        XCTAssertTrue(ExerciseSearch.matches(name: "Incline Smith Press", query: "mit"))
    }

    func testNoMatchWhenAnyWordIsMissing() {
        XCTAssertFalse(ExerciseSearch.matches(name: "Row", query: "press"))
        XCTAssertFalse(ExerciseSearch.matches(name: "Lat Pulldown – Neutral", query: "lat wide"))
        let items = [Item(name: "Row", archived: false)]
        XCTAssertTrue(ExerciseSearch.filter(items, query: "squat", name: \.name, isArchived: \.archived).isEmpty)
    }

    func testRankingPutsFirstWordPrefixFirstThenAlphabetical() {
        let items = ["Seated Row", "Row – Chest Supported", "Cable Row", "Rowing Machine", "Bench"]
            .map { Item(name: $0, archived: false) }
        let result = ExerciseSearch.filter(items, query: "row", name: \.name, isArchived: \.archived)
        XCTAssertEqual(result.map(\.name), ["Row – Chest Supported", "Rowing Machine", "Cable Row", "Seated Row"])
        let accents = ExerciseSearch.filter([Item(name: "B Élévation", archived: false),
                                             Item(name: "Élévation A", archived: false)],
                                            query: "elev", name: \.name, isArchived: \.archived)
        XCTAssertEqual(accents.map(\.name), ["Élévation A", "B Élévation"])
    }

    func testMatchRangesCoverEveryWordAndMerge() {
        let name = "Lat Pulldown – Neutral"
        let ranges = ExerciseSearch.matchRanges(name: name, query: "neutral lat")
        XCTAssertEqual(ranges.map { String(name[$0]) }, ["Lat", "Neutral"])
        let overlapping = ExerciseSearch.matchRanges(name: "Pulldown", query: "pull ulld")
        XCTAssertEqual(overlapping.map { String("Pulldown"[$0]) }, ["Pulld"])
        let repeated = ExerciseSearch.matchRanges(name: "Row Row", query: "ROW")
        XCTAssertEqual(repeated.count, 2)
        XCTAssertEqual(ExerciseSearch.matchRanges(name: "Café", query: "cafe").map { String("Café"[$0]) }, ["Café"])
        XCTAssertTrue(ExerciseSearch.matchRanges(name: "Row", query: "").isEmpty)
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
