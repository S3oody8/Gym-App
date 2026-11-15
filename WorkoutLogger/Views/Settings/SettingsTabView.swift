import SwiftUI

/// Placeholder for the Settings tab (built in a later step).
struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Settings coming soon", systemImage: "square.dashed")
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTabView()
}
