import Foundation

/// Coordinates **mindmap-connection** persistence between **mindmap-nodes** against **`/mindmap-connection`**.
final class MindmapConnectionController: Sendable {
    private let remote: MindmapConnectionRemoteDataSource

    init(remote: MindmapConnectionRemoteDataSource = MindmapConnectionRemoteDataSource()) {
        self.remote = remote
    }

    /// Creates a directed **mindmap-connection** from **`sourceNodeId`** at **`sourceAnchor`**. Omit **`targetNodeId`** / **`targetAnchor`** together for an open-ended link; set both when the target is known. Returns the server **`ConnectionModel`** (**`201`**).
    func addMindmapConnection(
        sourceNodeId: String,
        sourceAnchor: ConnectionAnchor,
        targetNodeId: String? = nil,
        targetAnchor: ConnectionAnchor? = nil,
        mindmapId: String,
        accessToken: String
    ) async throws -> ConnectionModel {
        precondition(
            (targetNodeId == nil) == (targetAnchor == nil),
            "targetNodeId and targetAnchor must both be nil or both non-nil"
        )
        let (data, response) = try await remote.addMindmapConnection(
            sourceNodeId: sourceNodeId,
            sourceAnchor: sourceAnchor,
            targetNodeId: targetNodeId,
            targetAnchor: targetAnchor,
            mindmapId: mindmapId,
            accessToken: accessToken
        )
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(ConnectionModel.self, from: data)
    }

    /// Applies a partial update (**`PATCH …/mindmap-connection/{id}`**) to a **mindmap-connection**. Omit parameters to leave those fields unchanged. Use **`setTargetNodeIdToNull`** / **`setTargetAnchorToNull`** to clear target fields per the API. Returns the updated **`ConnectionModel`** (**`200`**).
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
    ) async throws -> ConnectionModel {
        let (data, response) = try await remote.updateMindmapConnection(
            mindmapConnectionId: mindmapConnectionId,
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            setTargetNodeIdToNull: setTargetNodeIdToNull,
            sourceAnchor: sourceAnchor,
            targetAnchor: targetAnchor,
            setTargetAnchorToNull: setTargetAnchorToNull,
            accessToken: accessToken
        )
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(ConnectionModel.self, from: data)
    }

    /// Deletes the **mindmap-connection** with **`mindmapConnectionId`**. **`204`** from the API is treated as success.
    func deleteMindmapConnection(mindmapConnectionId: String, accessToken: String) async throws {
        let (_, response) = try await remote.deleteMindmapConnection(
            mindmapConnectionId: mindmapConnectionId,
            accessToken: accessToken
        )
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }
}
