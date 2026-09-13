import Foundation

final class UsageStubProtocol: URLProtocol, @unchecked Sendable {
    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let status = Int(url.lastPathComponent) ?? 200
        let body = [
            "method": request.httpMethod ?? "",
            "authorization": request.value(forHTTPHeaderField: "Authorization") ?? "",
            "userAgent": request.value(forHTTPHeaderField: "User-Agent") ?? "",
            "cookie": request.value(forHTTPHeaderField: "Cookie") ?? ""
        ]
        guard let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Retry-After": "600"]
        ), let data = try? JSONEncoder().encode(body) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
