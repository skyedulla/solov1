import Foundation

private enum MindmapNodeRemoteDataSourceError: Error {
    /// **`POST`** / **`PATCH`** **`/mindmap-node`** API (**mindmap-nodes** resource).
    case onlyMindmapNodesSupported
}

private struct CreateMindmapNodeRequestBody: Encodable {
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

private struct FullMindmapNodeSyncPatchBody: Encodable {
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

/// **Mindmap-node** (**`/mindmap-node`**) API I/O via **`URLSession`** only.
final class MindmapNodeRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`GET {base}/mindmap-node?mindmap_id=…&q=…`** with **`Authorization: Bearer`**. Response is capped at **5** **mindmap-nodes** (server). Empty **`query`** omits **`q`**.
    func searchMindmapNodes(mindmapId: String, query: String, accessToken: String) async throws -> (Data, URLResponse) {
        let resourceURL = baseURL.appendingPathComponent("mindmap-node", isDirectory: false)
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

    /// Creates **`mindmapNode`** via **`POST {base}/mindmap-node`** (server assigns **`id`**).
    func addMindmapNode(_ mindmapNode: NodeModel, accessToken: String) async throws -> (Data, URLResponse) {
        guard case let .mindmapNode(payload) = mindmapNode.nodeType else {
            throw MindmapNodeRemoteDataSourceError.onlyMindmapNodesSupported
        }
        let url = baseURL.appendingPathComponent("mindmap-node", isDirectory: false)
        let body = CreateMindmapNodeRequestBody(
            mindmapId: payload.mindmapId,
            parentNodeId: mindmapNode.parentNodeId,
            position: mindmapNode.position,
            text: payload.text,
            dimensions: mindmapNode.dimensions
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

    /// Updates **`mindmapNode`** via **`PATCH {base}/mindmap-node/{id}`** with a full field snapshot.
    func editMindmapNode(_ mindmapNode: NodeModel, accessToken: String) async throws -> (Data, URLResponse) {
        guard case let .mindmapNode(payload) = mindmapNode.nodeType else {
            throw MindmapNodeRemoteDataSourceError.onlyMindmapNodesSupported
        }
        let url = baseURL
            .appendingPathComponent("mindmap-node", isDirectory: false)
            .appendingPathComponent(mindmapNode.id, isDirectory: false)

        let patch = FullMindmapNodeSyncPatchBody(
            mindmapId: payload.mindmapId,
            parentNodeId: mindmapNode.parentNodeId,
            position: mindmapNode.position,
            text: payload.text,
            dimensions: mindmapNode.dimensions
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

    /// **`DELETE {base}/mindmap-node/{id}`** with **`Authorization: Bearer`** (**mindmap-node** row).
    func deleteMindmapNode(mindmapNodeId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("mindmap-node", isDirectory: false)
            .appendingPathComponent(mindmapNodeId, isDirectory: false)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await session.data(for: request)
    }
}
