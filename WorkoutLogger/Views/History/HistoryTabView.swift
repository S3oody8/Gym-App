import SwiftUI

/// Placeholder for the History tab (built in a later step).
struct HistoryTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("No sessions yet", systemImage: "square.dashed")
                .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryTabView()
}
