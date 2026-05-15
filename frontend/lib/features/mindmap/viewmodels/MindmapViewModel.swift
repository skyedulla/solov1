import Foundation

/// Canvas / editor: load a full **`MindmapModel`** and list mind maps for an idea. For create / delete / summary, use **`MindmapManagementViewModel`**.
final class MindmapViewModel: Sendable {
    private let controller: MindmapController

    init(controller: MindmapController = MindmapController()) {
        self.controller = controller
    }

    func listMindmaps(ideaId: String, accessToken: String) async throws -> [MindmapSummaryModel] {
        try await controller.listMindmaps(ideaId: ideaId, accessToken: accessToken)
    }

    func loadMindmap(id: String, ideaId: String, accessToken: String) async throws -> MindmapModel {
        try await controller.loadMindmap(id: id, ideaId: ideaId, accessToken: accessToken)
    }
}
