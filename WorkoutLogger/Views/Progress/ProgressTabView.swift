import SwiftUI

/// Placeholder for the Progress tab (built in a later step).
struct ProgressTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("No data yet", systemImage: "square.dashed")
                .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressTabView()
}
