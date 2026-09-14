import Foundation
@testable import RationsProviders

enum CursorTestData {
    static func token(
        subject: String = "auth0|test-account", expiry: Date = .now.addingTimeInterval(3600)
    ) throws -> String {
        let payload = try ProviderTestData.json([
            "sub": subject, "email": "cursor@example.invalid", "exp": expiry.timeIntervalSince1970
        ])
        let encoded = payload.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return "eyJhbGciOiJSUzI1NiJ9.\(encoded).fixture"
    }

    static func summary(individual: [String: Any] = [:], team: [String: Any] = [:]) throws -> Data {
        try ProviderTestData.json([
            "membershipType": "ultra", "billingCycleEnd": ProviderTestData.now.addingTimeInterval(3600).ISO8601Format(),
            "individualUsage": individual, "teamUsage": team
        ])
    }
}
