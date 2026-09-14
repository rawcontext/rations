// Adapted from CodexBar's CursorAppAuth.swift; see Resources/CodexBarAttribution.txt.
import Foundation
import SQLite3

struct CursorAppAuth {
    static let databaseURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
        "Library/Application Support/Cursor/User/globalStorage/state.vscdb"
    )

    static func readToken(from url: URL = databaseURL) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else { throw signedOut() }
        let sidecarsExist = ["-wal", "-shm"].contains { FileManager.default.fileExists(atPath: url.path + $0) }
        // An idle WAL database must not recreate sidecars; a live WAL must remain visible.
        let filename = sidecarsExist ? url.path : url.absoluteString + "?immutable=1"
        let flags = SQLITE_OPEN_READONLY | (sidecarsExist ? 0 : SQLITE_OPEN_URI)
        var database: OpaquePointer?
        let status = sqlite3_open_v2(filename, &database, flags, nil)
        defer { sqlite3_close(database) }
        guard status == SQLITE_OK else { throw databaseUnavailable() }
        sqlite3_busy_timeout(database, 250)
        var statement: OpaquePointer?
        let query = "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1"
        let prepared = sqlite3_prepare_v2(database, query, -1, &statement, nil)
        defer { sqlite3_finalize(statement) }
        guard prepared == SQLITE_OK else { throw databaseUnavailable() }
        let result = sqlite3_step(statement)
        if result == SQLITE_DONE { throw signedOut() }
        guard result == SQLITE_ROW else { throw databaseUnavailable() }
        let count = Int(sqlite3_column_bytes(statement, 0))
        guard count > 0, count < 65_536, let bytes = sqlite3_column_blob(statement, 0) else { throw signedOut() }
        guard let token = decode(Data(bytes: bytes, count: count)), !token.isEmpty else { throw signedOut() }
        return token
    }

    static func decode(_ data: Data) -> String? {
        if !data.isEmpty, data.count.isMultiple(of: 2), stride(from: 0, to: data.count, by: 2).allSatisfy({
            (1..<128).contains(data[$0]) && data[$0 + 1] == 0
        }) {
            return String(data: data, encoding: .utf16LittleEndian)
        }
        return String(data: data, encoding: .utf8)
    }

    private static func signedOut() -> ProviderFailure {
        .notSignedIn("Sign in inside Cursor, then connect the account.")
    }

    private static func databaseUnavailable() -> ProviderFailure {
        .unavailable("Couldn't read Cursor's saved sign-in. Open Cursor and try again.")
    }
}
