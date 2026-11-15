import SwiftUI

/// Placeholder for the Workout tab (built in a later step).
struct WorkoutTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("No active workout", systemImage: "square.dashed")
                .navigationTitle("Workout")
        }
    }
}

#Preview {
    WorkoutTabView()
}
