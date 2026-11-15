import SwiftUI
import UserNotifications

/// Settings. Data and Health sections are added in later steps.
struct SettingsTabView: View {
    @AppStorage(SettingsKeys.restAlertEnabled)
    private var restAlertEnabled = SettingsKeys.defaultRestAlertEnabled
    @AppStorage(SettingsKeys.restAlertSeconds)
    private var restAlertSeconds = SettingsKeys.defaultRestAlertSeconds
    @State private var notificationsDenied = false
    @State private var dataViewModel = DataSettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Rest alert", isOn: $restAlertEnabled)
                    if restAlertEnabled {
                        LabeledContent("Alert after",
                                       value: RestTimerMath.format(TimeInterval(restAlertSeconds)))
                        RestAlertTimePicker(totalSeconds: $restAlertSeconds)
                    }
                } header: {
                    Text("Rest Timer")
                } footer: {
                    if restAlertEnabled && notificationsDenied {
                        Text("Notifications are turned off for this app. Turn them on in the iOS Settings app to get rest alerts.")
                            .foregroundStyle(.red)
                    } else {
                        Text("The rest timer always counts. The alert sends a notification once per rest period. Changes apply from the next rest period.")
                    }
                }

                HealthSettingsSection()

                DataSettingsSection(viewModel: dataViewModel)
            }
            .modifier(DataSettingsPresentation(viewModel: dataViewModel))
            .navigationTitle("Settings")
            .onChange(of: restAlertEnabled) { _, enabled in
                if enabled {
                    RestAlertNotifier.shared.requestAuthorization()
                } else {
                    RestAlertNotifier.shared.cancel()
                }
            }
            .task(id: restAlertEnabled) {
                let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                notificationsDenied = status == .denied
            }
        }
    }
}

#Preview {
    SettingsTabView()
}
