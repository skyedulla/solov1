import Foundation

/// Type-specific **`mindmap-node`** payload: **`mindmap_id`** + **`text`** on the wire.
struct MindmapNodeModel: Codable, Sendable, Equatable {
    /// Default canvas size for a new mind map node (**200×50** px).
    static let defaultDimensions = NodeModel.Dimensions(height: 50, width: 200)

    var mindmapId: String
    var text: String
}
