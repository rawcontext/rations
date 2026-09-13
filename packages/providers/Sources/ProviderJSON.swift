import CoreFoundation
import Foundation

struct ProviderJSON {
    let values: [String: Any]

    init(_ data: Data) throws {
        guard let values = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderFailure.invalidResponse
        }
        self.values = values
    }

    init(values: [String: Any]) { self.values = values }

    func object(_ key: String) -> Self? {
        (values[key] as? [String: Any]).map(Self.init(values:))
    }

    func objects(_ key: String) -> [Self] {
        (values[key] as? [[String: Any]] ?? []).map(Self.init(values:))
    }

    func string(_ key: String) -> String? {
        guard let value = values[key] as? String, !value.isEmpty else { return nil }
        return value
    }

    func number(_ key: String) -> Double? {
        guard let value = values[key] as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID() else { return nil }
        let number = value.doubleValue
        return number.isFinite ? number : nil
    }

    func bool(_ key: String) -> Bool? { values[key] as? Bool }

    static func date(_ string: String?) -> Date? {
        guard let string else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }

    static func claims(_ token: String?) -> Self? {
        guard let payload = token?.split(separator: ".").dropFirst().first else { return nil }
        var encoded = String(payload).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        encoded += String(repeating: "=", count: (4 - encoded.count % 4) % 4)
        return Data(base64Encoded: encoded).flatMap { try? Self($0) }
    }
}
