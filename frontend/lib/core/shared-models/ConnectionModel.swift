import Foundation

/// Which edge of a node a mind map link attaches to.
enum ConnectionAnchor: String, Codable, Sendable {
    case top
    case right
    case left
    case bottom
}

/// A directed link between two vertices. **`target`** fields are **`nil`** until the link is completed.
/// **`connectionType`** tells whether the edge is scoped by **`mindmap_id`** (**`MindmapConnection`**) or **`decision_map_id`** (**`DecisionConnection`**).
struct ConnectionModel: Codable, Sendable {
    enum ConnectionType: Sendable, Equatable {
        /// **`mindmap_id`** in wire JSON — mind map scoped edge (**`MindmapConnectionModel`** payload).
        case mindmapConnection(MindmapConnectionModel)
        /// **`decision_map_id`** in wire JSON — decision map scoped edge (**`DecisionConnectionModel`** payload).
        case decisionConnection(DecisionConnectionModel)
    }

    var id: String
    var connectionType: ConnectionType
    var sourceNodeId: String
    var targetNodeId: String?
    var sourceAnchor: ConnectionAnchor
    var targetAnchor: ConnectionAnchor?

    enum CodingKeys: String, CodingKey {
        case id
        case mindmapId = "mindmap_id"
        case decisionMapId = "decision_map_id"
        case sourceNodeId = "source_node_id"
        case targetNodeId = "target_node_id"
        case sourceAnchor = "source_anchor"
        case targetAnchor = "target_anchor"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        sourceNodeId = try c.decode(String.self, forKey: .sourceNodeId)
        targetNodeId = try c.decodeIfPresent(String.self, forKey: .targetNodeId)
        sourceAnchor = try c.decode(ConnectionAnchor.self, forKey: .sourceAnchor)
        targetAnchor = try c.decodeIfPresent(ConnectionAnchor.self, forKey: .targetAnchor)

        if let decisionMapId = try c.decodeIfPresent(String.self, forKey: .decisionMapId) {
            connectionType = .decisionConnection(DecisionConnectionModel(decisionMapId: decisionMapId))
        } else {
            let mindmapId = try c.decode(String.self, forKey: .mindmapId)
            connectionType = .mindmapConnection(MindmapConnectionModel(mindmapId: mindmapId))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(sourceNodeId, forKey: .sourceNodeId)
        try c.encodeIfPresent(targetNodeId, forKey: .targetNodeId)
        try c.encode(sourceAnchor, forKey: .sourceAnchor)
        try c.encodeIfPresent(targetAnchor, forKey: .targetAnchor)
        switch connectionType {
        case let .mindmapConnection(scope):
            try c.encode(scope.mindmapId, forKey: .mindmapId)
        case let .decisionConnection(scope):
            try c.encode(scope.decisionMapId, forKey: .decisionMapId)
        }
    }
}
