import Foundation

struct EmbeddingsSearchRequest: Encodable {

    let query: String?
    let vectorStore: String

    enum CodingKeys: String, CodingKey {
        case query = "Query"
        case vectorStore = "VectorStore"
    }
}
