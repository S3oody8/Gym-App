import SwiftUI

/// Settings → Apple Health: toggle to write finished workouts (only in builds with HealthKit).
struct HealthSettingsSection: View {
    @AppStorage(SettingsKeys.healthKitEnabled) private var enabled = false
    @AppStorage(HealthSync.lastResultKey) private var lastResult = ""
    @State private var errorMessage: String?

    var body: some View {
        Section {
            if HealthSync.isCompiledIn {
                Toggle("Save workouts to Apple Health", isOn: $enabled)
                    .onChange(of: enabled) { _, isOn in
                        guard isOn else { return }
                        Task { await authorize() }
                    }
            } else {
                Text("Apple Health isn't included in this build of the app.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Apple Health")
        } footer: {
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else if HealthSync.isCompiledIn {
                Text(lastResult.isEmpty
                     ? "Each finished workout is saved as Traditional Strength Training (start, end, duration)."
                     : lastResult)
            }
        }
    }

    private func authorize() async {
        let health = HealthSync.shared
        guard health.isAvailable else {
            errorMessage = "Apple Health isn't available on this device."
            enabled = false
            return
        }
        do {
            try await health.requestAuthorization()
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't get Apple Health access: \(error.localizedDescription)"
            enabled = false
        }
    }
}
