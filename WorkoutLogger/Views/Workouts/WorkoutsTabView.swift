import SwiftData
import SwiftUI

/// Workouts tab: Start workout, "From template" pills, then history grouped under
/// THIS WEEK / LAST WEEK / <Month Year>. Tap a row to open it; swipe left to delete (undo toast).
struct WorkoutsTabView: View {
    /// Opens the live workout full screen (owned by the root view).
    let openWorkout: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(PRCache.self) private var prCache
    @Query(filter: #Predicate<WorkoutSession> { $0.finishedAt == nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var activeSessions: [WorkoutSession]
    @Query(filter: #Predicate<WorkoutSession> { $0.finishedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]

    @State private var viewModel = HistoryViewModel()
    @State private var path: [WorkoutSession] = []
    /// Deleted once the detail screens have been popped, so no view reads a deleted session.
    @State private var deleteAfterPop: WorkoutSession?
    @State private var renaming: WorkoutSession?
    @State private var renameText = ""
    @State private var confirmDeleteTemplate: WorkoutTemplate?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    startButton
                    if !templates.isEmpty { templateRow }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                if sessions.isEmpty {
                    Text("Finished workouts appear here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSubtle)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                let prCounts = prCache.countsBySession
                ForEach(HistoryGrouping.groups(sessions, date: \.startedAt)) { group in
                    Section {
                        ForEach(group.items) { session in
                            historyRow(session, prCount: prCounts[session.id] ?? 0)
                        }
                    } header: {
                        SectionLabel(group.title)
                            .padding(.top, 8)
                    }
                    .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Workouts")
            .navigationDestination(for: WorkoutSession.self) { session in
                PastWorkoutView(session: session) {
                    deleteAfterPop = session
                    path.removeAll()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.deletedSnapshot != nil {
                    UndoToastView(message: "Workout deleted") { viewModel.undoDelete(in: context) }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: viewModel.deletedSnapshot)
            .alert("Rename Workout", isPresented: Binding(
                get: { renaming != nil }, set: { if !$0 { renaming = nil } }
            )) {
                TextField("Workout", text: $renameText)
                    .textInputAutocapitalization(.words)
                Button("Save") { saveRename() }
                Button("Cancel", role: .cancel) { renaming = nil }
            }
            .confirmationDialog(
                "Delete template \(confirmDeleteTemplate?.name ?? "")?",
                isPresented: Binding(get: { confirmDeleteTemplate != nil },
                                     set: { if !$0 { confirmDeleteTemplate = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Template", role: .destructive) { deleteTemplate() }
            } message: {
                Text("Past workouts are not affected.")
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { (viewModel.saveErrorMessage ?? errorMessage) != nil },
                set: { if !$0 { viewModel.saveErrorMessage = nil; errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveErrorMessage ?? errorMessage ?? "")
            }
            .onChange(of: path) { _, newPath in
                if newPath.isEmpty, let session = deleteAfterPop {
                    deleteAfterPop = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        viewModel.delete(session, in: context)
                    }
                }
            }
            .onAppear {
                if [.historyDetail, .historyDeleteFromDetail].contains(DebugScenario.current),
                   path.isEmpty, let first = sessions.first {
                    path = [first]
                }
            }
        }
    }

    // MARK: Start

    private var hasActiveWorkout: Bool { !activeSessions.isEmpty }

    private var startButton: some View {
        Button {
            if hasActiveWorkout {
                openWorkout()
            } else {
                start { try $0.startSession() }
            }
        } label: {
            Text(hasActiveWorkout ? "Workout in progress" : "Start workout")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: Theme.primaryButtonHeight)
                .foregroundStyle(hasActiveWorkout ? Theme.text : Theme.onAccent)
                .background(hasActiveWorkout ? Theme.raised : Theme.accent,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var templateRow: some View {
        HStack(spacing: 10) {
            Text("From template")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
                .fixedSize()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(templates) { template in
                        Button {
                            start { try $0.startSession(from: template) }
                        } label: {
                            Text(template.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.text)
                                .padding(.horizontal, 14)
                                .frame(minHeight: Theme.pillHeight)
                                .background(Theme.raised, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(hasActiveWorkout)
                        .opacity(hasActiveWorkout ? 0.5 : 1)
                        .contextMenu {
                            Button("Delete Template", systemImage: "trash", role: .destructive) {
                                confirmDeleteTemplate = template
                            }
                        }
                        .accessibilityHint("Starts a workout from this template")
                    }
                }
            }
        }
        .frame(minHeight: Theme.minTouch)
    }

    private func start(_ action: (WorkoutStore) throws -> WorkoutSession) {
        guard !hasActiveWorkout else { return openWorkout() }
        if RestAlertSettings.current().enabled {
            RestAlertNotifier.shared.requestAuthorization()
        }
        do {
            _ = try action(WorkoutStore(context: context))
            openWorkout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: History

    private func historyRow(_ session: WorkoutSession, prCount: Int) -> some View {
        HistoryRowView(session: session, summary: prCache.summary(for: session), prCount: prCount)
            .overlay { NavigationLink(value: session) { EmptyView() }.opacity(0) }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    viewModel.delete(session, in: context)
                }
                .tint(Theme.destructive)
                Button("Rename", systemImage: "pencil") {
                    renameText = session.name
                    renaming = session
                }
                .tint(Theme.raised)
            }
    }

    private func saveRename() {
        if let session = renaming {
            do {
                try WorkoutStore(context: context).rename(
                    session, to: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                viewModel.saveErrorMessage = error.localizedDescription
            }
        }
        renaming = nil
    }

    private func deleteTemplate() {
        if let template = confirmDeleteTemplate {
            do {
                try WorkoutStore(context: context).deleteTemplate(template)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        confirmDeleteTemplate = nil
    }
}
