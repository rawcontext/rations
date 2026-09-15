import Foundation
import RationsCore
import RationsProviders

enum ConnectionDiagnostics {
    static func writeIfRequested(_ state: LiveAccountState) {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--connection-report"), index + 1 < arguments.count else { return }
        let providers = ProviderID.allCases.map { provider -> [String: Any] in
            let accounts = state.accounts.filter { $0.profile.provider == provider }
            return [
                "provider": provider.rawValue,
                "accounts": accounts.map { account in
                    ["plan": account.profile.plan ?? "unknown", "error": account.error ?? "",
                     "errorKind": account.issue?.rawValue ?? "",
                     "notice": account.notice ?? "",
                     "fetchedAt": account.fetchedAt?.ISO8601Format() as Any? ?? NSNull(),
                     "resetCredits": account.resetCredits as Any? ?? NSNull(),
                     "windows": account.rows.flatMap(\.windows).map { window -> [String: Any] in
                         ["label": window.label, "usedPercent": window.usedPercent as Any? ?? NSNull(),
                          "resetsAt": window.resetsAt?.ISO8601Format() as Any? ?? NSNull()]
                     }] as [String: Any]
                },
                "error": state.providerErrors[provider]?.message ?? "",
                "errorKind": state.providerErrors[provider]?.kind.rawValue ?? ""
            ]
        }
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
        guard let data = try? JSONSerialization.data(withJSONObject: providers, options: options) else {
            return
        }
        try? data.write(to: URL(fileURLWithPath: arguments[index + 1]), options: .atomic)
    }
}
