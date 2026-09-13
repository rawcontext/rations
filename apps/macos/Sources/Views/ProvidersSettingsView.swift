import RationsCore
import SwiftUI

struct ProvidersSettingsView: View {
    let store: RationsStore

    var body: some View {
        Form {
            Section {
                ForEach(ProviderID.allCases) { provider in
                    ProviderSettingsRow(provider: provider, store: store, showsToggle: true)
                }
            } header: {
                Text("Providers")
            } footer: {
                Text("Rations uses existing sign-ins on this Mac. Provider connections are still being implemented.")
            }
        }
        .formStyle(.grouped)
    }
}
