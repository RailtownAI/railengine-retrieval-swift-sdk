import Foundation

public struct EngineDocument: Decodable, Sendable {
    public let engineDocumentId: String?
    public let eventId: String
    public let projectId: String
    public let engineId: String
    public let customerKey: String
    public let content: String
    public let version: Int
    public let dateCreated: String
    public let dateUpdated: String?
}
