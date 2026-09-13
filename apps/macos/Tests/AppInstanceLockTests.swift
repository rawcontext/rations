import Foundation
import Testing

struct AppInstanceLockTests {
    @Test
    func onlyOneCopyCanHoldTheSameInstanceLock() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("app.lock")
        var first = try AppInstanceLock.claim(at: file)
        #expect(first != nil)
        #expect(try AppInstanceLock.claim(at: file) == nil)
        first = nil
        let replacement = try AppInstanceLock.claim(at: file)
        #expect(replacement != nil)
    }

    @Test
    func differentBundleLocksCanCoexist() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let production = try AppInstanceLock.claim(at: directory.appendingPathComponent("production.lock"))
        let development = try AppInstanceLock.claim(at: directory.appendingPathComponent("development.lock"))
        #expect(production != nil)
        #expect(development != nil)
    }
}
