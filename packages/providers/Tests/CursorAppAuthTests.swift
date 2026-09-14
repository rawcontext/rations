import Foundation
@testable import RationsProviders
import Testing

struct CursorAppAuthTests {
    @Test(arguments: [nil, String.Encoding.utf8, .utf16LittleEndian])
    func readsTextAndEncodedBlobsWithoutModifyingTheDatabase(_ encoding: String.Encoding?) throws {
        let fixture = try CursorDatabaseFixture()
        let token = try CursorTestData.token()
        try fixture.store(token, encoding: encoding)
        fixture.close()
        let before = try Data(contentsOf: fixture.url)
        #expect(try CursorAppAuth.readToken(from: fixture.url) == token)
        #expect(try Data(contentsOf: fixture.url) == before)
    }

    @Test
    func readsUncheckpointedSignInChangesFromTheLiveWAL() throws {
        let fixture = try CursorDatabaseFixture(wal: true)
        try fixture.store("first-session")
        #expect(try CursorAppAuth.readToken(from: fixture.url) == "first-session")
        try fixture.store("second-session")
        #expect(try CursorAppAuth.readToken(from: fixture.url) == "second-session")
    }

    @Test
    func idleWALDoesNotRecreateVendorSidecars() throws {
        let fixture = try CursorDatabaseFixture(wal: true)
        try fixture.store("saved-session")
        fixture.close()
        for suffix in ["-wal", "-shm"] {
            let sidecar = URL(fileURLWithPath: fixture.url.path + suffix)
            if FileManager.default.fileExists(atPath: sidecar.path) { try FileManager.default.removeItem(at: sidecar) }
        }
        #expect(try CursorAppAuth.readToken(from: fixture.url) == "saved-session")
        #expect(!FileManager.default.fileExists(atPath: fixture.url.path + "-wal"))
        #expect(!FileManager.default.fileExists(atPath: fixture.url.path + "-shm"))
    }

    @Test
    func missingSignInDoesNotCreateOrPopulateACursorDatabase() throws {
        let fixture = try CursorDatabaseFixture()
        #expect(throws: ProviderFailure.self) { try CursorAppAuth.readToken(from: fixture.url) }
        let missing = fixture.directory.appendingPathComponent("missing.vscdb")
        #expect(throws: ProviderFailure.self) { try CursorAppAuth.readToken(from: missing) }
        #expect(!FileManager.default.fileExists(atPath: missing.path))
    }
}
