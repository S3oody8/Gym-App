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
    @State private var showTemplates = DebugScenario.current == .templatePicker

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
            VStack(spacing: 12) {
                Button {
                    showTemplates = true
                } label: {
                    Text("Start from Template")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
                Button {
                    start { try $0.startSession() }
                } label: {
                    Text("Start Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(isPresented: $showTemplates) {
            TemplatePickerView { template in
                start { try $0.startSession(from: template) }
            }
        }
    }

    private func start(_ action: (WorkoutStore) throws -> WorkoutSession) {
        if RestAlertSettings.current().enabled {
            RestAlertNotifier.shared.requestAuthorization()
        }
        do {
            _ = try action(WorkoutStore(context: context))
        } catch {
            startError = error.localizedDescription
        }
    }
}

#Preview {
    WorkoutTabView()
        .modelContainer(try! ModelSchema.makeContainer(inMemory: true))
}
