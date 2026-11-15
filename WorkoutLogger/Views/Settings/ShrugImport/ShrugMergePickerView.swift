import SwiftUI

/// Pick the exercise a Shrug exercise should be merged into.
struct ShrugMergePickerView: View {
    let source: String
    let targets: [String]
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List(targets.filter { ExerciseSearch.matches(name: $0, query: search) }, id: \.self) { name in
                Button(name) {
                    onPick(name)
                    dismiss()
                }
                .tint(.primary)
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Merge “\(source)” into")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
