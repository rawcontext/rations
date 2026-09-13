import Foundation
@testable import RationsProviders
import Testing

struct KeychainAccessTests {
    @Test
    func backgroundOperationsDisableLegacyPromptsAndRestoreThePreviousState() throws {
        let fixture = KeychainInteractionFixture()
        let access = gate(fixture)
        let result = try access.perform {
            #expect(!fixture.getAllowed())
            return "cached credential"
        }
        #expect(result == "cached credential")
        #expect(fixture.history == [false, true])
    }

    @Test
    func failedReadRestoresInteractionPolicy() {
        let fixture = KeychainInteractionFixture()
        #expect(throws: ProviderFailure.self) {
            try gate(fixture).perform { throw ProviderFailure.keychain(-25308) }
        }
        #expect(fixture.getAllowed())
        #expect(fixture.history == [false, true])
    }

    @Test
    func explicitConnectionCanPromptAndRestoresNoninteractiveState() throws {
        let fixture = KeychainInteractionFixture()
        fixture.setAllowed(false)
        try gate(fixture).perform(interactive: true) { #expect(fixture.getAllowed()) }
        #expect(!fixture.getAllowed())
        #expect(fixture.history == [false, true, false])
    }

    @Test
    func refusesToReadIfPromptSuppressionCannotBeEnabled() {
        let access = KeychainAccess(getAllowed: { true }, setAllowed: { _ in throw ProviderFailure.keychain(-50) })
        #expect(throws: ProviderFailure.self) {
            try access.perform { Issue.record("Keychain query ran without the required prompt policy") }
        }
    }

    @Test
    func concurrentProviderReadsAndUserActionsDoNotMixPromptPolicies() {
        let fixture = KeychainInteractionFixture()
        let access = gate(fixture)
        DispatchQueue.concurrentPerform(iterations: 50) { index in
            let interactive = index.isMultiple(of: 3)
            do {
                try access.perform(interactive: interactive) { #expect(fixture.getAllowed() == interactive) }
            } catch { Issue.record(error) }
        }
        let history = fixture.history
        #expect(history.count == 100)
        for offset in stride(from: 1, to: history.count, by: 2) { #expect(history[offset]) }
    }

    private func gate(_ fixture: KeychainInteractionFixture) -> KeychainAccess {
        KeychainAccess(getAllowed: { fixture.getAllowed() }, setAllowed: { fixture.setAllowed($0) })
    }
}
