import SwiftUI

/// An exercise name with the parts matching the search query in the accent colour, semibold.
struct HighlightedNameText: View {
    let name: String
    let query: String

    var body: some View {
        Text(attributed)
    }

    private var attributed: AttributedString {
        var result = AttributedString(name)
        for range in ExerciseSearch.matchRanges(name: name, query: query) {
            guard let attributedRange = Range(range, in: result) else { continue }
            result[attributedRange].foregroundColor = .accentColor
            result[attributedRange].inlinePresentationIntent = .stronglyEmphasized
        }
        return result
    }
}
