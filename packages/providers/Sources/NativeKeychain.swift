import Foundation
import LocalAuthentication
import Security

enum NativeKeychain {
    static func read(service: String, account: String? = nil, interactive: Bool = false) throws -> [Data] {
        try KeychainAccess.shared.perform(interactive: interactive) {
            try readItems(service: service, account: account, interactive: interactive)
        }
    }

    static func readItems(
        service: String, account: String?, interactive: Bool,
        copyMatching: (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching
    ) throws -> [Data] {
        let context = LAContext()
        context.interactionNotAllowed = !interactive
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service,
            kSecMatchLimit: kSecMatchLimitAll, kSecReturnAttributes: true, kSecUseAuthenticationContext: context
        ]
        if let account {
            query[kSecAttrAccount] = account
            query[kSecMatchLimit] = kSecMatchLimitOne
            query[kSecReturnAttributes] = nil
            query[kSecReturnData] = true
        }
        var result: CFTypeRef?
        let status = copyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw ProviderFailure.keychain(status) }
        if account != nil {
            guard let data = result as? Data else { throw ProviderFailure.invalidResponse }
            return [data]
        }
        return try (result as? [[CFString: Any]] ?? []).map { attributes in
            var item: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword, kSecAttrService: service,
                kSecMatchLimit: kSecMatchLimitOne, kSecReturnData: true,
                kSecUseAuthenticationContext: context
            ]
            item[kSecAttrAccount] = attributes[kSecAttrAccount]
            var value: CFTypeRef?
            let status = copyMatching(item as CFDictionary, &value)
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
