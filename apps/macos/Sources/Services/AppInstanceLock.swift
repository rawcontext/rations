import Darwin
import Foundation

final class AppInstanceLock {
    private let descriptor: Int32

    private init(descriptor: Int32) { self.descriptor = descriptor }
    deinit { close(descriptor) }

    static func claim(at file: URL) throws -> AppInstanceLock? {
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let descriptor = open(file.path, O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0o600)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        if flock(descriptor, LOCK_EX | LOCK_NB) == 0 { return AppInstanceLock(descriptor: descriptor) }
        let failure = errno
        close(descriptor)
        if failure == EWOULDBLOCK { return nil }
        throw POSIXError(POSIXErrorCode(rawValue: failure) ?? .EIO)
    }
}
