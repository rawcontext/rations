import RationsCore
import SwiftUI

extension RationsStore {
    func binding<Value>(_ keyPath: WritableKeyPath<DisplayPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { self.preferences[keyPath: keyPath] },
            set: { value in self.updatePreferences { $0[keyPath: keyPath] = value } }
        )
    }

    func enabledBinding(for provider: ProviderID) -> Binding<Bool> {
        Binding(
            get: { !self.preferences.disabledProviders.contains(provider) },
            set: { enabled in
                self.updatePreferences { value in
                    if enabled { value.disabledProviders.remove(provider) } else {
                        value.disabledProviders.insert(provider)
                    }
                }
            }
        )
    }
}
