import Foundation

private struct CreateNodeRequestBody: Encodable {
    let ideaId: String
    let mindmapId: String
    let parentNodeId: String?
    let position: NodeModel.Position
    let text: String
    let dimensions: NodeModel.Dimensions

    enum CodingKeys: String, CodingKey {
        case ideaId
        case mindmapId
        case parentNodeId
        case position
        case text
        case dimensions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ideaId, forKey: .ideaId)
        try container.encode(mindmapId, forKey: .mindmapId)
        try container.encodeIfPresent(parentNodeId, forKey: .parentNodeId)
        try container.encode(position, forKey: .position)
        try container.encode(text, forKey: .text)
        try container.encode(dimensions, forKey: .dimensions)
    }
}

private struct FullNodeSyncPatchBody: Encodable {
    let ideaId: String
    let mindmapId: String
    let parentNodeId: String?
    let position: NodeModel.Position
    let text: String
    let dimensions: NodeModel.Dimensions

    enum CodingKeys: String, CodingKey {
        case ideaId
        case mindmapId
        case parentNodeId
        case position
        case text
        case dimensions
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ideaId, forKey: .ideaId)
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

    /// Syncs **`node`**: **`POST`** when **`isNew`** (server assigns **`id`**); **`PATCH …/nodes/{id}`** with a full field snapshot when not new.
    func syncNodeToServer(_ node: NodeModel, isNew: Bool, accessToken: String) async throws -> (Data, URLResponse) {
        if isNew {
            let url = baseURL.appendingPathComponent("nodes", isDirectory: false)
            let body = CreateNodeRequestBody(
                ideaId: node.ideaId,
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

        let url = baseURL
            .appendingPathComponent("nodes", isDirectory: false)
            .appendingPathComponent(node.id, isDirectory: false)

        let patch = FullNodeSyncPatchBody(
            ideaId: node.ideaId,
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
