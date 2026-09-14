import Foundation
@testable import RationsProviders
import SQLite3

final class CursorDatabaseFixture {
    let directory: URL
    let url: URL
    private var database: OpaquePointer?

    init(wal: Bool = false) throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("rations-cursor-" + UUID().uuidString)
        url = directory.appendingPathComponent("state.vscdb")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        guard sqlite3_open(url.path, &database) == SQLITE_OK else { throw ProviderFailure.invalidResponse }
        if wal { sqlite3_exec(database, "PRAGMA journal_mode=WAL", nil, nil, nil) }
        let status = sqlite3_exec(database, "CREATE TABLE ItemTable (key TEXT PRIMARY KEY, value BLOB)", nil, nil, nil)
        guard status == SQLITE_OK else { throw ProviderFailure.invalidResponse }
    }

    func store(_ token: String, encoding: String.Encoding? = nil) throws {
        let value = encoding == nil ? "CAST(? AS TEXT)" : "?"
        let query = "INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('cursorAuth/accessToken', \(value))"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let data = token.data(using: encoding ?? .utf8) else { throw ProviderFailure.invalidResponse }
        let status = data.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, 1, bytes.baseAddress, Int32(bytes.count), nil)
            return sqlite3_step(statement)
        }
        guard status == SQLITE_DONE else { throw ProviderFailure.invalidResponse }
    }

    func close() { sqlite3_close(database); database = nil }

    deinit {
        close()
        try? FileManager.default.removeItem(at: directory)
    }
}
