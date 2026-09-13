import SwiftUI

struct RationsSettings: View {
    @Bindable var store: RationsStore
    let loginItem: LoginItemManager

    var body: some View {
        Group {
            switch store.selectedTab {
            case .general: GeneralSettingsView(store: store, loginItem: loginItem)
            case .accounts: AccountsSettingsView(store: store)
            case .providers: ProvidersSettingsView(store: store)
            }
        }
        .frame(width: 560, height: 450)
        .alert("Rations", isPresented: Binding(
            get: { store.message != nil }, set: { if !$0 { store.message = nil } }
        )) {
            Button("OK", role: .cancel) { store.message = nil }
        } message: {
            Text(store.message ?? "")
        }
    }
}
