import Foundation

protocol ContentDecoding: Sendable {
    func decode<T: Decodable & Sendable>(_ content: String) throws(RailengineError) -> T
}

struct JSONContentDecoder: ContentDecoding {

    func decode<T: Decodable & Sendable>(_ content: String) throws(RailengineError) -> T {
        do {
            return try JSONDecoder().decode(T.self, from: Data(content.utf8))
        } catch {
            throw RailengineError.decodingFailed(description: error.localizedDescription)
        }
    }
}
