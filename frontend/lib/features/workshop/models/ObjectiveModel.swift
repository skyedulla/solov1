import Foundation

/// A single workshop objective (always tied to an idea).
struct ObjectiveModel: Codable, Sendable {
    var id: String
    var ideaId: String
    var text: String
    var isCompleted: Bool
}
