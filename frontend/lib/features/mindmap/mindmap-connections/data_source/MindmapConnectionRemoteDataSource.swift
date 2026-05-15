import Foundation

private struct CreateMindmapConnectionRequestBody: Encodable {
    let mindmapId: String
    let sourceNodeId: String
    let targetNodeId: String?
    let sourceAnchor: ConnectionAnchor
    let targetAnchor: ConnectionAnchor?

    enum CodingKeys: String, CodingKey {
        case mindmapId
        case sourceNodeId
        case targetNodeId
        case sourceAnchor
        case targetAnchor
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mindmapId, forKey: .mindmapId)
        try container.encode(sourceNodeId, forKey: .sourceNodeId)
        try container.encodeIfPresent(targetNodeId, forKey: .targetNodeId)
        try container.encode(sourceAnchor, forKey: .sourceAnchor)
        try container.encodeIfPresent(targetAnchor, forKey: .targetAnchor)
    }
}

private struct UpdateMindmapConnectionRequestBody: Encodable {
    var mindmapId: String?
    var sourceNodeId: String?
    var targetNodeId: String?
    /// When **`true`**, encodes **`targetNodeId`**: **`null`** (clear open-ended link target). Mutually exclusive with non-**`nil`** **`targetNodeId`**.
    var setTargetNodeIdToNull: Bool
    var sourceAnchor: ConnectionAnchor?
    var targetAnchor: ConnectionAnchor?
    /// When **`true`**, encodes **`targetAnchor`**: **`null`**.
    var setTargetAnchorToNull: Bool

    enum CodingKeys: String, CodingKey {
        case mindmapId
        case sourceNodeId
        case targetNodeId
        case sourceAnchor
        case targetAnchor
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(mindmapId, forKey: .mindmapId)
        try container.encodeIfPresent(sourceNodeId, forKey: .sourceNodeId)
        if setTargetNodeIdToNull {
            try container.encodeNil(forKey: .targetNodeId)
        } else if let targetNodeId {
            try container.encode(targetNodeId, forKey: .targetNodeId)
        }
        try container.encodeIfPresent(sourceAnchor, forKey: .sourceAnchor)
        if setTargetAnchorToNull {
            try container.encodeNil(forKey: .targetAnchor)
        } else if let targetAnchor {
            try container.encode(targetAnchor, forKey: .targetAnchor)
        }
    }
}

/// **Mindmap-connection** (**`/mindmap-connection`**, edge) API I/O via **`URLSession`** (`POST` / **`PATCH …/mindmap-connection/{id}`** / **`DELETE …/mindmap-connection/{id}`**).
final class MindmapConnectionRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    func addMindmapConnection(
        sourceNodeId: String,
        sourceAnchor: ConnectionAnchor,
        targetNodeId: String? = nil,
        targetAnchor: ConnectionAnchor? = nil,
        mindmapId: String,
        accessToken: String
    ) async throws -> (Data, URLResponse) {
        let url = baseURL.appendingPathComponent("mindmap-connection", isDirectory: false)
        let body = CreateMindmapConnectionRequestBody(
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

    /// **`PATCH {base}/mindmap-connection/{id}`** — only non-**`nil`** (or explicit null) fields are encoded; omit parameters to leave server fields unchanged. Expected response **`200`** with a **`ConnectionModel`** body (**mindmap-connection** wire JSON).
    func updateMindmapConnection(
        mindmapConnectionId: String,
        mindmapId: String? = nil,
        sourceNodeId: String? = nil,
        targetNodeId: String? = nil,
        setTargetNodeIdToNull: Bool = false,
        sourceAnchor: ConnectionAnchor? = nil,
        targetAnchor: ConnectionAnchor? = nil,
        setTargetAnchorToNull: Bool = false,
        accessToken: String
    ) async throws -> (Data, URLResponse) {
        precondition(!(targetNodeId != nil && setTargetNodeIdToNull), "targetNodeId and setTargetNodeIdToNull cannot both be set")
        precondition(!(targetAnchor != nil && setTargetAnchorToNull), "targetAnchor and setTargetAnchorToNull cannot both be set")

        let url = baseURL
            .appendingPathComponent("mindmap-connection", isDirectory: false)
            .appendingPathComponent(mindmapConnectionId, isDirectory: false)

        let body = UpdateMindmapConnectionRequestBody(
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            setTargetNodeIdToNull: setTargetNodeIdToNull,
            sourceAnchor: sourceAnchor,
            targetAnchor: targetAnchor,
            setTargetAnchorToNull: setTargetAnchorToNull
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

    func deleteMindmapConnection(mindmapConnectionId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("mindmap-connection", isDirectory: false)
            .appendingPathComponent(mindmapConnectionId, isDirectory: false)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await session.data(for: request)
    }
}
