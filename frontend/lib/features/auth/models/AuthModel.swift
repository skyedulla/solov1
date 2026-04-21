public struct AuthModel: Codable, Sendable {
    public var firstName: String
    public var lastName: String
    public var email: String
    public var password: String

    public init(firstName: String, lastName: String, email: String, password: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
    }
}
