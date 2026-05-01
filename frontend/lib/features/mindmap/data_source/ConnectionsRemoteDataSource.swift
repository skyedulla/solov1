import Foundation

private struct CreateConnectionRequestBody: Encodable {
    let ideaId: String
    let mindmapId: String
    let sourceNodeId: String
    let targetNodeId: String?
    let sourceAnchor: ConnectionAnchor
    let targetAnchor: ConnectionAnchor?

    enum CodingKeys: String, CodingKey {
        case ideaId
        case mindmapId
        case sourceNodeId
        case targetNodeId
        case sourceAnchor
        case targetAnchor
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ideaId, forKey: .ideaId)
        try container.encode(mindmapId, forKey: .mindmapId)
        try container.encode(sourceNodeId, forKey: .sourceNodeId)
        try container.encodeIfPresent(targetNodeId, forKey: .targetNodeId)
        try container.encode(sourceAnchor, forKey: .sourceAnchor)
        try container.encodeIfPresent(targetAnchor, forKey: .targetAnchor)
    }
}

/// Mind map connection (**edge**) API I/O via **`URLSession`** (`POST` / **`DELETE …/connections/{id}`**).
final class ConnectionsRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    func addConnection(
        sourceNodeId: String,
        sourceAnchor: ConnectionAnchor,
        targetNodeId: String?,
        targetAnchor: ConnectionAnchor?,
        ideaId: String,
        mindmapId: String,
        accessToken: String
    ) async throws -> (Data, URLResponse) {
        let url = baseURL.appendingPathComponent("connections", isDirectory: false)
        let body = CreateConnectionRequestBody(
            ideaId: ideaId,
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            sourceAnchor: sourceAnchor,
            targetAnchor: targetAnchor
        )
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

    func deleteConnection(id: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("connections", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await session.data(for: request)
    }
}
