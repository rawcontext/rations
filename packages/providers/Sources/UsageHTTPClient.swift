import Foundation

struct UsageHTTPClient: Sendable {
    let session: URLSession

    init(session: URLSession? = nil) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        self.session = session ?? URLSession(
            configuration: configuration, delegate: UsageSessionDelegate(), delegateQueue: nil
        )
    }

    func request(
        _ url: URL, token: String? = nil, body: Data? = nil, headers: [String: String] = [:]
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = body == nil ? "GET" : "POST"
        request.httpBody = body
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Rations/0.1", forHTTPHeaderField: "User-Agent")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw ProviderFailure.invalidResponse }
        if response.statusCode == 429 {
            let deadline = Self.retryDate(response.value(forHTTPHeaderField: "Retry-After"), now: .now)
            throw ProviderFailure.rateLimited(deadline)
        }
        if response.statusCode == 401 {
            throw ProviderFailure.notSignedIn("The provider rejected this sign-in. Reconnect this account.")
        }
        guard (200..<300).contains(response.statusCode), data.count < 2_000_000 else {
            throw ProviderFailure.unavailable("Usage is unavailable from this provider (HTTP \(response.statusCode)).")
        }
        return data
    }

    static func retryDate(_ header: String?, now: Date) -> Date {
        let minimum = now.addingTimeInterval(60)
        guard let header else { return now.addingTimeInterval(300) }
        if let delay = Double(header), delay.isFinite { return max(minimum, now.addingTimeInterval(delay)) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return max(minimum, formatter.date(from: header) ?? now.addingTimeInterval(300))
    }

    func request(
        _ address: String, token: String, object: [String: String], headers: [String: String] = [:]
    ) async throws -> Data {
        guard let url = URL(string: address) else { throw ProviderFailure.invalidResponse }
        return try await request(url, token: token, body: JSONEncoder().encode(object), headers: headers)
    }
}
