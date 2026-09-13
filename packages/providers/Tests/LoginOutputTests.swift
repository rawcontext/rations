import Foundation
@testable import RationsProviders
import Testing

struct LoginOutputTests {
    @Test
    func waitsForTheEntireBrowserURL() throws {
        var output = LoginOutput()
        let prefix = "https://auth.openai.com/oauth/authorize?client_id=test&state="
        try output.append(Array(prefix.utf8)[...])
        #expect(output.authorizationURL == nil)
        try output.append(Array("complete\n".utf8)[...])
        #expect(output.authorizationURL?.query?.hasSuffix("state=complete") == true)
    }

    @Test(arguments: [
        "https://auth.openai.com.evil.invalid/oauth/authorize\n",
        "file:///private/auth.json\n",
        "https://example.invalid/oauth/authorize\n"
    ])
    func doesNotOfferUnrecognizedBrowserDestinations(_ value: String) {
        #expect(LoginOutput.authorizationURL(in: value) == nil)
    }

    @Test
    func codexCommandIsIsolatedFromTheCurrentCLIAccount() throws {
        let folder = URL(fileURLWithPath: "/fixture/managed-login")
        let command = try LoginCommand.make(
            .codex, directory: folder, executable: URL(fileURLWithPath: "/fixture/codex"),
            environment: ["CODEX_HOME": "/fixture/existing-cli", "PATH": "/usr/bin:/bin"]
        )
        #expect(command.environment["CODEX_HOME"] == folder.path)
        #expect(command.environment["PATH"] == "/usr/bin:/bin")
        #expect(command.arguments == ["login", "-c", "cli_auth_credentials_store=\"file\""])
    }
}
