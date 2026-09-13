import RationsCore
import SwiftUI

struct ProvidersSettingsView: View {
    let store: RationsStore

    var body: some View {
        Form {
            Section {
                ForEach(ProviderID.allCases) { provider in
                    ProviderSettingsRow(provider: provider, store: store)
                }
            } header: {
                Text("Providers")
            } footer: {
                Text("Saved accounts and credentials stay in your Mac's Keychain.")
            }
        }
        .formStyle(.grouped)
    }
}
