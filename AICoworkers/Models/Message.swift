import Foundation

// Make MessageType conform to String and Codable
enum MessageType: String, Codable {
    case user
    case ai
}

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: MessageType
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, type: MessageType, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
    }
}
