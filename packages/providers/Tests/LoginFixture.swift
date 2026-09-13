import Foundation
@testable import RationsProviders

struct LoginFixture {
    let directory: URL
    let executable: URL

    init(script: String) throws {
        let name = "rations-login-test-" + UUID().uuidString
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]
        )
        executable = directory.appendingPathComponent("vendor")
        try Data(("#!/bin/sh\n" + script + "\n").utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
    }

    var command: LoginCommand {
        LoginCommand(executable: executable, arguments: [], directory: directory, environment: [:])
    }

    func cleanUp() { try? FileManager.default.removeItem(at: directory) }
}
