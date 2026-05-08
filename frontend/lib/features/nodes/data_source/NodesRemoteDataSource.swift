import Foundation

private struct CreateNodeRequestBody: Encodable {
    let mindmapId: String
    let parentNodeId: String?
    let position: NodeModel.Position
    let text: String
    let dimensions: NodeModel.Dimensions

    enum CodingKeys: String, CodingKey {
        case mindmapId
        case parentNodeId
        case position
        case text
        case dimensions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mindmapId, forKey: .mindmapId)
        try container.encodeIfPresent(parentNodeId, forKey: .parentNodeId)
        try container.encode(position, forKey: .position)
        try container.encode(text, forKey: .text)
        try container.encode(dimensions, forKey: .dimensions)
    }
}

private struct FullNodeSyncPatchBody: Encodable {
    let mindmapId: String
    let parentNodeId: String?
    let position: NodeModel.Position
    let text: String
    let dimensions: NodeModel.Dimensions

    enum CodingKeys: String, CodingKey {
        case mindmapId
        case parentNodeId
        case position
        case text
        case dimensions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mindmapId, forKey: .mindmapId)
        if let parentNodeId {
            try container.encode(parentNodeId, forKey: .parentNodeId)
        } else {
            try container.encodeNil(forKey: .parentNodeId)
        }
        try container.encode(position, forKey: .position)
        try container.encode(text, forKey: .text)
        try container.encode(dimensions, forKey: .dimensions)
    }
}

/// Mind map node API I/O via **`URLSession`** only.
final class NodesRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`GET {base}/nodes?mindmap_id=…&q=…`** with **`Authorization: Bearer`**. Response is capped at **5** nodes (server). Empty **`query`** omits **`q`**.
    func searchNodes(mindmapId: String, query: String, accessToken: String) async throws -> (Data, URLResponse) {
        let resourceURL = baseURL.appendingPathComponent("nodes", isDirectory: false)
        var components = URLComponents(url: resourceURL, resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "mindmap_id", value: mindmapId)]
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Creates **`node`** via **`POST {base}/nodes`** (server assigns **`id`**).
    func addNode(_ node: NodeModel, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL.appendingPathComponent("nodes", isDirectory: false)
        let body = CreateNodeRequestBody(
            mindmapId: node.mindmapId,
            parentNodeId: node.parentNodeId,
            position: node.position,
            text: node.text,
            dimensions: node.dimensions
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

    /// Updates **`node`** via **`PATCH {base}/nodes/{id}`** with a full field snapshot.
    func editNode(_ node: NodeModel, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("nodes", isDirectory: false)
            .appendingPathComponent(node.id, isDirectory: false)

        let patch = FullNodeSyncPatchBody(
            mindmapId: node.mindmapId,
            parentNodeId: node.parentNodeId,
            position: node.position,
            text: node.text,
            dimensions: node.dimensions
        )
        let encoder = JSONEncoder()
        let json = try encoder.encode(patch)

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = json
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`DELETE {base}/nodes/{id}`** with **`Authorization: Bearer`**.
    func deleteNode(id: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("nodes", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await session.data(for: request)
    }
}
