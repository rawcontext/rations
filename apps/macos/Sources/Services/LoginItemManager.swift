import Observation
import ServiceManagement

@MainActor @Observable
final class LoginItemManager {
    private(set) var enabled: Bool
    private(set) var error: String?
    private let isPreview: Bool

    init(isPreview: Bool) {
        self.isPreview = isPreview
        enabled = isPreview || SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ value: Bool) {
        if isPreview { enabled = value; return }
        do {
            if value { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            enabled = SMAppService.mainApp.status == .enabled
            error = SMAppService.mainApp.status == .requiresApproval
                ? "Allow Rations in System Settings → General → Login Items." : nil
        } catch {
            self.error = "Couldn't update launch at login. Check Login Items in System Settings."
        }
    }
}
