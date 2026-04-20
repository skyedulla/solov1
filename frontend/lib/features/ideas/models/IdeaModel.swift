import Foundation

/// Idea entity fields.
struct IdeaModel: Codable, Sendable {
    var id: String
    var title: String
    var description: String
    var isPublished: Bool
    var createdAt: Date
    var lastUpdatedAt: Date
    var targetUser: String
    var purpose: String
}
