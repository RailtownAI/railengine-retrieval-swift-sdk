import Foundation

struct StoragePagedResponse: Decodable {
    let items: [StoragePagedItem]
    let totalPages: Int
}

struct StoragePagedItem: Decodable {
    let eventId: String
    let projectId: String
    let engineId: String
    let customerKey: String
    let content: String
    let version: Int
    let dateCreated: String
    let dateUpdated: String?

    var asEngineDocument: EngineDocument {
        EngineDocument(
            engineDocumentId: nil,
            eventId: eventId,
            projectId: projectId,
            engineId: engineId,
            customerKey: customerKey,
            content: content,
            version: version,
            dateCreated: dateCreated,
            dateUpdated: dateUpdated
        )
    }
}
