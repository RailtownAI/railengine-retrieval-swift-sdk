import Foundation

public struct SearchDocument: Decodable, Sendable {

    public let eventId: String
    public let projectId: String
    public let engineId: String
    public let customerKey: String
    public let score: Double
    public let content: String
}
