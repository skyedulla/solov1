import Foundation

/// Coordinates **mindmap-node** persistence (search, add, edit, delete) against **`/mindmap-node`**.
final class MindmapNodeController: Sendable {
    private let remote: MindmapNodeRemoteDataSource

    init(remote: MindmapNodeRemoteDataSource = MindmapNodeRemoteDataSource()) {
        self.remote = remote
    }

    /// At most **5** **mindmap-nodes**. Non-empty **`query`**: case-insensitive match on **`text`**, ordered by the substring **after** the first match of **`query`**. Empty **`query`**: first five by **`text`** (A–Z), then **`id`**.
    func searchMindmapNodes(mindmapId: String, query: String, accessToken: String) async throws -> [NodeModel] {
        let (data, response) = try await remote.searchMindmapNodes(
            mindmapId: mindmapId,
            query: query,
            accessToken: accessToken
        )
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        // **`NodeModel`** (mindmap-node wire shape) uses explicit snake_case **`CodingKeys`**; avoid **`.convertFromSnakeCase`** here.
        return try decoder.decode([NodeModel].self, from: data)
    }

    /// Creates **`mindmapNode`** on the server (**`POST`**). Local **`id`** is ignored until the response returns the server row. Expects **`201`**. Returns the **`NodeModel`** from the response body.
    func addMindmapNode(_ mindmapNode: NodeModel, accessToken: String) async throws -> NodeModel {
        let (data, response) = try await remote.addMindmapNode(mindmapNode, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(NodeModel.self, from: data)
    }

    /// Updates **`mindmapNode`** on the server (**`PATCH …/mindmap-node/{id}`**). Expects **`200`**. Returns the **`NodeModel`** from the response body.
    func editMindmapNode(_ mindmapNode: NodeModel, accessToken: String) async throws -> NodeModel {
        let (data, response) = try await remote.editMindmapNode(mindmapNode, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(NodeModel.self, from: data)
    }

    /// Deletes the **mindmap-node** with **`mindmapNodeId`**. **`204`** from the API is treated as success.
    func deleteMindmapNode(mindmapNodeId: String, accessToken: String) async throws {
        let (_, response) = try await remote.deleteMindmapNode(mindmapNodeId: mindmapNodeId, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }
}
