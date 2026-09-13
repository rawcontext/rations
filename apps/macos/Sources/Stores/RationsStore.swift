import Foundation
import Observation
import RationsCore

@MainActor @Observable
final class RationsStore {
    var preferences: DisplayPreferences {
        didSet { persistPreferences() }
    }
    var accounts: [AccountReading]
    var activeAccounts: [ProviderID: String] = [:]
    var selectedTab = SettingsTab.general
    var message: String?
    let isPreview: Bool
    private let defaults: UserDefaults?

    init(isPreview: Bool) {
        self.isPreview = isPreview
        defaults = isPreview ? nil : .standard
        let saved = defaults?.data(forKey: "displayPreferences")
        var preferences = saved.flatMap { try? JSONDecoder().decode(DisplayPreferences.self, from: $0) }
            ?? DisplayPreferences()
        preferences.normalize()
        self.preferences = preferences
        accounts = isPreview ? DesignFixtures.accounts(now: .now) : []
        for account in accounts where activeAccounts[account.profile.provider] == nil {
            activeAccounts[account.profile.provider] = account.id
        }
    }

    func updatePreferences(_ update: (inout DisplayPreferences) -> Void) {
        var value = preferences
        update(&value)
        value.normalize()
        preferences = value
    }

    func rename(_ accountID: String, to name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].profile.name = name
    }

    func remove(_ accountID: String) {
        guard let account = accounts.first(where: { $0.id == accountID }), !isActive(account) else { return }
        accounts.removeAll { $0.id == accountID }
    }

    func isActive(_ account: AccountReading) -> Bool {
        activeAccounts[account.profile.provider] == account.id
    }

    func accounts(for provider: ProviderID) -> [AccountReading] {
        accounts.filter { $0.profile.provider == provider }
    }

    func refresh() {
        guard isPreview else {
            message = "Connect an account to see its usage. Provider connections are still being implemented."
            return
        }
        for index in accounts.indices { accounts[index].fetchedAt = .now }
    }

    private func persistPreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults?.set(data, forKey: "displayPreferences")
    }
}
