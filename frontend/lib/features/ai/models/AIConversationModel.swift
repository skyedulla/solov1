import Foundation

/// One AI thread scoped to **`ideaId`**, identified by **`id`**, holding an ordered transcript.
///
/// Decode with **`JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`** so **`idea_id`**, **`date_created`**, and **`last_updated_at`** wire to **`ideaId`**, **`dateCreated`**, and **`lastUpdatedAt`** without a local **`CodingKeys`** enum.
struct AIConversationModel: Codable, Sendable {
    var id: String
    var ideaId: String
    var title: String
    var dateCreated: Date
    var lastUpdatedAt: Date
    var messages: [AIMessageModel]
}
