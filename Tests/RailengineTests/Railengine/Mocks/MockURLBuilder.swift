import Foundation
@testable import Railengine

struct MockURLBuilder: URLBuilding {

    var storageURLsReturnNil: Bool = false

    func embeddingsSearchURL() -> URL {
        URL(string: "https://mock.test/api/Engine/mock-engine/Embeddings/Search")!
    }

    func indexingSearchURL() -> URL {
        URL(string: "https://mock.test/api/Engine/Indexing/Search")!
    }

    func storageEventIdURL(_ eventId: String) -> URL? {
        storageURLsReturnNil ? nil : URL(string: "https://mock.test/Storage?EventId=\(eventId)")
    }

    func storageCustomerKeyURL(_ customerKey: String, pageNumber: Int, pageSize: Int) -> URL? {
        storageURLsReturnNil ? nil : URL(string: "https://mock.test/Storage?CustomerKey=\(customerKey)")
    }

    func storageJsonPathURL(_ query: String, pageNumber: Int, pageSize: Int) -> URL? {
        storageURLsReturnNil ? nil : URL(string: "https://mock.test/Storage?JsonPathQuery=\(query)")
    }

    func storageListURL(pageNumber: Int, pageSize: Int) -> URL? {
        storageURLsReturnNil ? nil : URL(string: "https://mock.test/Storage?PageNumber=\(pageNumber)")
    }

    func deleteEventURL(_ eventId: String) -> URL {
        URL(string: "https://mock.test/api/Engine/mock-engine/Event/\(eventId)")!
    }
}
