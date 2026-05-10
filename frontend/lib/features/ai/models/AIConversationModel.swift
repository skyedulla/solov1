import Foundation

/// One AI thread scoped to **`ideaId`**, identified by **`id`**, holding an ordered transcript.
struct AIConversationModel: Codable, Sendable {
    var id: String
    var ideaId: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [AIMessageModel]?

    init(
        id: String,
        ideaId: String,
        title: String,
        createdAt: Date,
        updatedAt: Date,
        messages: [AIMessageModel]? = nil
    ) {
        self.id = id
        self.ideaId = ideaId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }
}
