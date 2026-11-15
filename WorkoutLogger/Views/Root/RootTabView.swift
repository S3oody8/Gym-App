import SwiftUI

/// Top-level tabs: Workout / History / Exercises / Progress / Settings.
struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Workout", systemImage: "figure.strengthtraining.traditional") {
                WorkoutTabView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryTabView()
            }
            Tab("Exercises", systemImage: "dumbbell") {
                ExercisesTabView()
            }
            Tab("Progress", systemImage: "chart.xyaxis.line") {
                ProgressTabView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsTabView()
            }
        }
    }
}

#Preview {
    RootTabView()
}
