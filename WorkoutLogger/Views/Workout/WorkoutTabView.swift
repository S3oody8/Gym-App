import SwiftData
import SwiftUI

/// Workout tab: the active workout if there is one, otherwise a Start button.
struct WorkoutTabView: View {
    @Environment(\.modelContext) private var context
    @Query(
        filter: #Predicate<WorkoutSession> { $0.finishedAt == nil },
        sort: \WorkoutSession.startedAt, order: .reverse
    )
    private var activeSessions: [WorkoutSession]
    @State private var startError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSessions.first {
                    ActiveWorkoutView(session: session, context: context)
                        .id(session.id)
                } else {
                    startView
                }
            }
        }
        .alert("Couldn't save", isPresented: Binding(
            get: { startError != nil }, set: { if !$0 { startError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(startError ?? "")
        }
    }

    private var startView: some View {
        ContentUnavailableView(
            "No Active Workout",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Start an empty workout and add exercises as you go.")
        )
        .navigationTitle("Workout")
        .safeAreaInset(edge: .bottom) {
            Button {
                do {
                    if UserDefaults.standard.object(forKey: SettingsKeys.restAlertEnabled) as? Bool
                        ?? SettingsKeys.defaultRestAlertEnabled {
                        RestAlertNotifier.shared.requestAuthorization()
                    }
                    try WorkoutStore(context: context).startSession()
                } catch {
                    startError = error.localizedDescription
                }
            } label: {
                Text("Start Workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

#Preview {
    WorkoutTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
