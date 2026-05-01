import Foundation

/// Which edge of a node a mind map link attaches to.
enum ConnectionAnchor: String, Codable, Sendable {
    case top
    case right
    case left
    case bottom
}

/// A directed link between two nodes in a mind map. **`target`** fields are **`nil`** until the link is completed.
struct ConnectionModel: Codable, Sendable {
    var id: String
    var ideaId: String
    var mindmapId: String
    var sourceNodeId: String
    var targetNodeId: String?
    var sourceAnchor: ConnectionAnchor
    var targetAnchor: ConnectionAnchor?

    enum CodingKeys: String, CodingKey {
        case id
        case ideaId = "idea_id"
        case mindmapId = "mindmap_id"
        case sourceNodeId = "source_node_id"
        case targetNodeId = "target_node_id"
        case sourceAnchor = "source_anchor"
        case targetAnchor = "target_anchor"
    }
}
