import Foundation

/// Scope for **`ConnectionModel.connectionType`** when the edge belongs to a mind map (**`mindmap_id`** in JSON).
struct MindmapConnectionModel: Codable, Sendable, Equatable {
    var mindmapId: String
}
