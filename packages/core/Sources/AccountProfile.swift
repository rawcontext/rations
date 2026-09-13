public struct AccountProfile: Identifiable, Equatable, Sendable {
    public let id: String
    public let provider: ProviderID
    public var name: String
    public let plan: String?
    public let email: String?

    public init(id: String, provider: ProviderID, name: String, plan: String?, email: String?) {
        self.id = id
        self.provider = provider
        self.name = name
        self.plan = plan
        self.email = email
    }

    public func displayEmail(redacted: Bool) -> String? {
        guard let email, redacted else { return email }
        guard let separator = email.lastIndex(of: "@") else { return "•••" }
        return "•••" + email[separator...]
    }
}
