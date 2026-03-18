struct IndexSearchRequest<Query: Encodable & Sendable>: Encodable, Sendable {
    let engineId: String
    let query: Query

    enum CodingKeys: String, CodingKey {
        case engineId = "EngineId"
        case query = "Query"
    }
}

struct IndexSearchResponse: Decodable {
    let value: [IndexDocument]
}
