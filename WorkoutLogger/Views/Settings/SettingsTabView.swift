import SwiftUI
import UserNotifications

/// Settings: LOGGING (quick buttons, ×2), REST TIMER (alert, alert time, lock screen timer),
/// DATA, and APPLE HEALTH in Health builds.
struct SettingsTabView: View {
    @AppStorage(SettingsKeys.restAlertEnabled)
    private var restAlertEnabled = SettingsKeys.defaultRestAlertEnabled
    @AppStorage(SettingsKeys.restAlertSeconds)
    private var restAlertSeconds = SettingsKeys.defaultRestAlertSeconds
    @AppStorage(SettingsKeys.liveActivityEnabled)
    private var liveActivityEnabled = SettingsKeys.defaultLiveActivityEnabled
    @AppStorage(SettingsKeys.showDoubleButton)
    private var showDouble = SettingsKeys.defaultShowDoubleButton
    @AppStorage(QuickButtons.keys[0]) private var quick1 = QuickButtons.defaults[0]
    @AppStorage(QuickButtons.keys[1]) private var quick2 = QuickButtons.defaults[1]
    @AppStorage(QuickButtons.keys[2]) private var quick3 = QuickButtons.defaults[2]
    @State private var notificationsDenied = false
    @State private var dataViewModel = DataSettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Quick buttons") {
                        HStack(spacing: 8) {
                            QuickButtonField(text: $quick1, slot: 1)
                            QuickButtonField(text: $quick2, slot: 2)
                            QuickButtonField(text: $quick3, slot: 3)
                        }
                    }
                    .foregroundStyle(Theme.text)
                    SwitchRow(title: "Show ×2 button", isOn: $showDouble)
                } header: {
                    SectionLabel("Logging")
                } footer: {
                    Text("Quick buttons add a set with fewer reps. Leave one empty to hide it.")
                        .foregroundStyle(Theme.textSubtle)
                }
                .listRowBackground(Theme.surface)

                Section {
                    SwitchRow(title: "Rest alert", isOn: $restAlertEnabled)
                    LabeledContent("Alert after",
                                   value: RestTimerMath.format(TimeInterval(restAlertSeconds)))
                        .foregroundStyle(Theme.text)
                    RestAlertTimePicker(totalSeconds: $restAlertSeconds)
                    SwitchRow(title: "Lock screen timer", isOn: $liveActivityEnabled)
                } header: {
                    SectionLabel("Rest timer")
                } footer: {
                    Group {
                        if restAlertEnabled && notificationsDenied {
                            Text("Notifications are turned off for this app. Turn them on in the iOS Settings app to get rest alerts.")
                                .foregroundStyle(Theme.destructive)
                        } else {
                            Text("The rest timer always counts. The alert sends one notification per rest period. Changes apply from the next rest period.")
                                .foregroundStyle(Theme.textSubtle)
                        }
                    }
                }
                .listRowBackground(Theme.surface)

                DataSettingsSection(viewModel: dataViewModel)
                    .listRowBackground(Theme.surface)

                if HealthSync.isCompiledIn {
                    HealthSettingsSection()
                        .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
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
