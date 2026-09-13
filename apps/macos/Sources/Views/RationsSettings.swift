import RationsCore
import SwiftUI

struct RationsSettings: View {
    var body: some View {
        Form {
            Section {
                ForEach(ProviderID.allCases) { provider in
                    LabeledContent(provider.displayName, value: "Not connected")
                }
            } header: {
                Text("Subscriptions")
            } footer: {
                Text("Account connections are not available in this development build.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 260)
    }
}
