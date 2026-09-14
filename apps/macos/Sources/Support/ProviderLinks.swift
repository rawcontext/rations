import AppKit
import RationsCore

enum ProviderLinks {
    static func open(_ provider: ProviderID) {
        let address: String
        switch provider {
        case .codex: address = "https://chatgpt.com/codex"
        case .claude: address = "https://claude.ai/settings/usage"
        case .antigravity: address = "https://antigravity.google/"
        case .grok: address = "https://grok.com/"
        case .cursor: address = "https://cursor.com/dashboard/spending"
        }
        guard let url = URL(string: address) else { return }
        NSWorkspace.shared.open(url)
    }
}
