import Foundation

struct LoginOutput {
    private var data = Data()
    private(set) var authorizationURL: URL?
    private(set) var needsReturn = false
    private(set) var portInUse = false

    mutating func append(_ bytes: ArraySlice<UInt8>) throws {
        data.append(contentsOf: bytes)
        guard data.count <= 1_000_000 else { throw ProviderFailure.invalidResponse }
        guard let text = String(data: data, encoding: .utf8) else { return }
        needsReturn = text.localizedCaseInsensitiveContains("press enter to open")
        portInUse = text.localizedCaseInsensitiveContains("address already in use")
        if authorizationURL == nil { authorizationURL = Self.authorizationURL(in: text) }
    }

    static func authorizationURL(in text: String) -> URL? {
        let pattern = #"https://[^\s\u001B<>\"]+(?=[\s\u001B])"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = expression.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            guard let range = Range(match.range, in: text), let url = URL(string: String(text[range])),
                  let host = url.host?.lowercased() else { continue }
            let hosts = ["auth.openai.com", "claude.ai", "claude.com", "platform.claude.com", "auth.x.ai"]
            if hosts.contains(host), url.path.contains("auth") { return url }
        }
        return nil
    }
}
