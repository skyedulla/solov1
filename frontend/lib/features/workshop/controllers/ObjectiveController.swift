import Foundation

/// Workshop objectives — create, edit text, toggle completion, delete.
final class ObjectiveController: Sendable {
    private let remote: ObjectivesRemoteDataSource

    init(remote: ObjectivesRemoteDataSource = ObjectivesRemoteDataSource()) {
        self.remote = remote
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// **`POST /objectives`** — returns persisted **`ObjectiveModel`** (**`201`**).
    func addObjective(text: String, accessToken: String) async throws -> ObjectiveModel {
        let (data, response) = try await remote.addObjective(text: text, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        return try Self.makeDecoder().decode(ObjectiveModel.self, from: data)
    }

    /// **`PATCH /objectives/:id`** — updates text only, **`200`**.
    func modifyObjective(id: String, text: String, accessToken: String) async throws -> ObjectiveModel {
        let (data, response) = try await remote.modifyObjective(id: id, text: text, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try Self.makeDecoder().decode(ObjectiveModel.self, from: data)
    }

    /// **`POST /objectives/:id/complete`** — flips **`isCompleted`**, **`200`**.
    func completeObjective(id: String, accessToken: String) async throws -> ObjectiveModel {
        let (data, response) = try await remote.completeObjective(id: id, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try Self.makeDecoder().decode(ObjectiveModel.self, from: data)
    }

    /// **`DELETE /objectives/:id`** — **`204`**.
    func deleteObjective(id: String, accessToken: String) async throws {
        let (_, response) = try await remote.deleteObjective(id: id, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }
}
