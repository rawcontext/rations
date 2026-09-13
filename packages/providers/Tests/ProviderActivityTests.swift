import RationsCore
@testable import RationsProviders
import Testing

struct ProviderActivityTests {
    @Test
    func oldRefreshIsRejectedDuringAndAfterSignIn() {
        var activity = ProviderActivity()
        let previous = activity.versions[.claude]
        let login = activity.begin(.claude)
        #expect(!activity.accepts(.claude, version: previous))
        #expect(activity.busy == [.claude])
        #expect(activity.accepts(.codex, version: nil))
        activity.finish(.claude, token: login)
        #expect(!activity.accepts(.claude, version: previous))
        #expect(activity.accepts(.claude, version: activity.versions[.claude]))
    }

    @Test
    func canceledLoginCannotUnlockItsReplacement() {
        var activity = ProviderActivity()
        let canceled = activity.begin(.codex)
        let replacement = activity.begin(.codex)
        activity.finish(.codex, token: canceled)
        #expect(activity.busy.contains(.codex))
        #expect(!activity.accepts(.codex, version: replacement))
        activity.finish(.codex, token: replacement)
        #expect(activity.busy.isEmpty)
    }
}
