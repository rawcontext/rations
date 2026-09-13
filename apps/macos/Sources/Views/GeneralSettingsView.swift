import RationsCore
import SwiftUI

struct GeneralSettingsView: View {
    let store: RationsStore
    let loginItem: LoginItemManager

    var body: some View {
        Form {
            menuSection
            thresholdSection
            refreshSection
            Section("Privacy") {
                Toggle(isOn: store.binding(\.hidePersonalInformation)) {
                    Text("Hide personal information")
                    Text("Emails are redacted in the menu. Nothing personal is shown in the menu bar.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped).controlSize(.small)
    }

    private var menuSection: some View {
        Section("Menu bar") {
            LabeledContent("Menu bar icon", value: "Two slices")
            Picker("Show usage as", selection: store.binding(\.usageMode)) {
                ForEach(UsageDisplayMode.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Reset time", selection: store.binding(\.resetMode)) {
                ForEach(ResetDisplayMode.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var thresholdSection: some View {
        Section("Thresholds") {
            Stepper(value: store.binding(\.warningRemaining), in: (store.preferences.criticalRemaining + 1)...100) {
                thresholdLabel("Warning when less than", value: store.preferences.warningRemaining)
            }
            Stepper(value: store.binding(\.criticalRemaining), in: 0...(store.preferences.warningRemaining - 1)) {
                thresholdLabel("Critical when less than", value: store.preferences.criticalRemaining)
            }
        }
    }

    private var refreshSection: some View {
        Section("Refresh") {
            Picker("Refresh every", selection: store.binding(\.refreshMinutes)) {
                ForEach(2...15, id: \.self) { Text("\($0) minutes").tag($0) }
            }
            Toggle("Launch at login", isOn: Binding(get: { loginItem.enabled }, set: loginItem.setEnabled))
            if let error = loginItem.error { Text(error).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func thresholdLabel(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value) % left").monospacedDigit().foregroundStyle(.secondary)
        }
    }
}
