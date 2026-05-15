import Foundation

/// Type-specific **decision-node** payload: **`decision_map_id`** + **`icon`** on the wire.
struct DecisionNodeModel: Codable, Sendable, Equatable {
    /// Default canvas size for a new decision node (**75×75** px).
    static let defaultDimensions = NodeModel.Dimensions(height: 75, width: 75)

    var decisionMapId: String
    var icon: String
}
