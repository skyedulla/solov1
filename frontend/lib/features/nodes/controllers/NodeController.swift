import Foundation

/// Coordinates mind map node persistence (search, add, edit, delete) against the API.
final class NodeController: Sendable {
    private let remote: NodesRemoteDataSource

    init(remote: NodesRemoteDataSource = NodesRemoteDataSource()) {
        self.remote = remote
    }

    /// At most **5** nodes. Non-empty **`query`**: case-insensitive match on **`text`**, ordered by the substring **after** the first match of **`query`**. Empty **`query`**: first five by **`text`** (A–Z), then **`id`**.
    func searchNodes(mindmapId: String, query: String, accessToken: String) async throws -> [NodeModel] {
        let (data, response) = try await remote.searchNodes(mindmapId: mindmapId, query: query, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        // **`NodeModel`** uses explicit snake_case **`CodingKeys`**; avoid **`.convertFromSnakeCase`** here.
        return try decoder.decode([NodeModel].self, from: data)
    }

    /// Creates **`node`** on the server (**`POST`**). Local **`id`** is ignored until the response returns the server row. Expects **`201`**. Returns the **`NodeModel`** from the response body.
    func addNode(_ node: NodeModel, accessToken: String) async throws -> NodeModel {
        let (data, response) = try await remote.addNode(node, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(NodeModel.self, from: data)
    }

    /// Updates **`node`** on the server (**`PATCH …/nodes/{id}`**). Expects **`200`**. Returns the **`NodeModel`** from the response body.
    func editNode(_ node: NodeModel, accessToken: String) async throws -> NodeModel {
        let (data, response) = try await remote.editNode(node, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(NodeModel.self, from: data)
    }

    /// Deletes the node with **`id`**. **`204`** from the API is treated as success.
    func deleteNode(id: String, accessToken: String) async throws {
        let (_, response) = try await remote.deleteNode(id: id, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }
}
