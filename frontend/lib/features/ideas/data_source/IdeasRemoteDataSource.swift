import Foundation

/// JSON body for **`POST …/ideas`** — camelCase keys; optional fields omitted when **`nil`**.
private struct CreateIdeaRequestBody: Encodable {
    let title: String
    let purpose: String
    let description: String?
    let targetUser: String?

    enum CodingKeys: String, CodingKey {
        case title
        case purpose
        case description
        case targetUser
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(purpose, forKey: .purpose)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(targetUser, forKey: .targetUser)
    }
}

/// JSON body for **`PATCH …/ideas/:id`** — camelCase; optional fields omitted when **`nil`** (unchanged on server).
private struct EditIdeaRequestBody: Encodable {
    let title: String
    let purpose: String
    let description: String?
    let targetUser: String?
    let isPublished: Bool?

    enum CodingKeys: String, CodingKey {
        case title
        case purpose
        case description
        case targetUser
        case isPublished
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(purpose, forKey: .purpose)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(targetUser, forKey: .targetUser)
        try container.encodeIfPresent(isPublished, forKey: .isPublished)
    }
}

/// Sends ideas list requests over the network via **`URLSession`** only — no routing or response interpretation here.
final class IdeasRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`GET {base}/ideas?sort=…&q=…`** with **`Authorization: Bearer`** — returns the raw **`URLSession`** result.
    func fetchIdeas(filter: IdeaFilterModel, accessToken: String) async throws -> (Data, URLResponse) {
        let resourceURL = baseURL.appendingPathComponent("ideas", isDirectory: false)
        var components = URLComponents(url: resourceURL, resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "sort", value: filter.sortBy)]
        let q = filter.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: q))
        }
        components.queryItems = queryItems
        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`POST {base}/ideas`** with JSON body (**`title`**, **`purpose`** required; **`description`**, **`targetUser`** optional) and **`Authorization: Bearer`** — returns raw **`URLSession`** result.
    func createNewIdea(title: String, purpose: String, description: String?, targetUser: String?, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL.appendingPathComponent("ideas", isDirectory: false)

        let body = CreateIdeaRequestBody(title: title, purpose: purpose, description: description, targetUser: targetUser)
        let encoder = JSONEncoder()
        let json = try encoder.encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`PATCH {base}/ideas/{id}`** with JSON body (**`title`**, **`purpose`** required; **`description`**, **`targetUser`** optional) and **`Authorization: Bearer`**.
    func editIdea(
        id: String,
        title: String,
        purpose: String,
        description: String?,
        targetUser: String?,
        isPublished: Bool? = nil,
        accessToken: String
    ) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("ideas", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)

        let body = EditIdeaRequestBody(
            title: title,
            purpose: purpose,
            description: description,
            targetUser: targetUser,
            isPublished: isPublished
        )
        let encoder = JSONEncoder()
        let json = try encoder.encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = json
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`DELETE {base}/ideas/{id}`** with **`Authorization: Bearer`** — returns raw **`URLSession`** result (expect **`204`**).
    func deleteIdea(id: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("ideas", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await session.data(for: request)
    }
}
