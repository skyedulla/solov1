import Foundation

/// Scope for **`ConnectionModel.connectionType`** when the edge belongs to a decision map (**`decision_map_id`** in JSON).
struct DecisionConnectionModel: Codable, Sendable, Equatable {
    var decisionMapId: String
}
