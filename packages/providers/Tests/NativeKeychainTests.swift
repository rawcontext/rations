import Foundation
import LocalAuthentication
@testable import RationsProviders
import Security
import Testing

struct NativeKeychainTests {
    @Test(arguments: [false, true])
    func scopedCredentialNeedsOnlyOneKeychainQuery(_ interactive: Bool) throws {
        let credential = Data("synthetic credential".utf8)
        var calls = 0
        let values = try NativeKeychain.readItems(
            service: "gemini", account: "antigravity", interactive: interactive
        ) { query, result in
            calls += 1
            let query = query as NSDictionary
            #expect(query[kSecAttrService] as? String == "gemini")
            #expect(query[kSecAttrAccount] as? String == "antigravity")
            #expect(query[kSecMatchLimit] as? String == kSecMatchLimitOne as String)
            #expect(query[kSecReturnData] as? Bool == true)
            #expect(query[kSecReturnAttributes] == nil)
            let context = query[kSecUseAuthenticationContext] as? LAContext
            #expect(context?.interactionNotAllowed == !interactive)
            result?.pointee = credential as CFData
            return errSecSuccess
        }
        #expect(values == [credential])
        #expect(calls == 1)
    }

    @Test(arguments: [errSecUserCanceled, errSecAuthFailed, errSecInteractionNotAllowed])
    func scopedReadDoesNotRepeatADeniedOrCancelledQuery(_ status: OSStatus) {
        var calls = 0
        #expect(throws: ProviderFailure.self) {
            try NativeKeychain.readItems(service: "gemini", account: "antigravity", interactive: true) { _, _ in
                calls += 1
                return status
            }
        }
        #expect(calls == 1)
    }

    @Test
    func unscopedVaultStillEnumeratesAttributesBeforeReadingEachAccount() throws {
        let credential = Data("saved account".utf8)
        var calls = 0
        let values = try NativeKeychain.readItems(
            service: "test-vault", account: nil, interactive: false
        ) { query, result in
            calls += 1
            let query = query as NSDictionary
            if calls == 1 {
                #expect(query[kSecReturnData] == nil)
                #expect(query[kSecReturnAttributes] as? Bool == true)
                result?.pointee = [[kSecAttrAccount: "fixture-account"]] as CFArray
            } else {
                #expect(query[kSecAttrAccount] as? String == "fixture-account")
                #expect(query[kSecReturnData] as? Bool == true)
                result?.pointee = credential as CFData
            }
            return errSecSuccess
        }
        #expect(values == [credential])
        #expect(calls == 2)
    }
}
