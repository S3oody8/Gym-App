import SwiftUI

/// Placeholder for the Exercises tab (built in a later step).
struct ExercisesTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("No exercises yet", systemImage: "square.dashed")
                .navigationTitle("Exercises")
        }
    }
}

#Preview {
    ExercisesTabView()
}
