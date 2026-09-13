import Foundation
import LocalAuthentication
import Security

enum NativeKeychain {
    static func read(service: String, account: String? = nil, interactive: Bool = false) throws -> [Data] {
        try KeychainAccess.shared.perform(interactive: interactive) {
            try readItems(service: service, account: account, interactive: interactive)
        }
    }

    private static func readItems(service: String, account: String?, interactive: Bool) throws -> [Data] {
        let context = LAContext()
        context.interactionNotAllowed = !interactive
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service,
            kSecMatchLimit: kSecMatchLimitAll, kSecReturnAttributes: true, kSecUseAuthenticationContext: context
        ]
        if let account { query[kSecAttrAccount] = account }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw ProviderFailure.keychain(status) }
        return try (result as? [[CFString: Any]] ?? []).map { attributes in
            var item: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword, kSecAttrService: service,
                kSecMatchLimit: kSecMatchLimitOne, kSecReturnData: true,
                kSecUseAuthenticationContext: context
            ]
            item[kSecAttrAccount] = attributes[kSecAttrAccount]
            var value: CFTypeRef?
            let status = SecItemCopyMatching(item as CFDictionary, &value)
            guard status == errSecSuccess else { throw ProviderFailure.keychain(status) }
            guard let data = value as? Data else { throw ProviderFailure.invalidResponse }
            return data
        }
    }

    static func unwrapGoKeyring(_ data: Data) -> Data {
        guard let text = String(data: data, encoding: .utf8), text.hasPrefix("go-keyring-base64:") else { return data }
        return Data(base64Encoded: String(text.dropFirst("go-keyring-base64:".count))) ?? data
    }
}
