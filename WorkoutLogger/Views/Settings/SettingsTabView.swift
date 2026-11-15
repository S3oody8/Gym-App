import SwiftUI

/// Settings. Further sections (rest timer, data, Health) are added in later steps.
struct SettingsTabView: View {
    @AppStorage(SettingsKeys.secondaryMusclesEnabled)
    private var secondaryEnabled = SettingsKeys.defaultSecondaryMusclesEnabled

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Secondary muscles", isOn: $secondaryEnabled)
                } header: {
                    Text("Exercises")
                } footer: {
                    Text("When off, secondary muscles are hidden and only primary muscles count toward volume.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTabView()
}
