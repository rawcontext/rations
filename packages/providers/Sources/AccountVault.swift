import Foundation
import Security

struct AccountVault {
    private let service = "com.rawcontext.rations.accounts"

    func load() throws -> [AccountConnection] {
        try NativeKeychain.read(service: service).map { try JSONDecoder().decode(AccountConnection.self, from: $0) }
    }

    func save(_ account: AccountConnection) throws {
        var query = baseQuery()
        query[kSecAttrAccount] = account.profile.id
        let data = try JSONEncoder().encode(account)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData] = data
            let added = SecItemAdd(query as CFDictionary, nil)
            guard added == errSecSuccess else { throw ProviderFailure.keychain(added) }
        } else if status != errSecSuccess { throw ProviderFailure.keychain(status) }
    }

    func remove(_ id: String) throws {
        var query = baseQuery()
        query[kSecAttrAccount] = id
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw ProviderFailure.keychain(status) }
    }

    private func baseQuery() -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service]
    }
}
