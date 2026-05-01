import Foundation

/// A single workshop objective.
struct ObjectiveModel: Codable, Sendable {
    var id: String
    var text: String
    var isCompleted: Bool
}
