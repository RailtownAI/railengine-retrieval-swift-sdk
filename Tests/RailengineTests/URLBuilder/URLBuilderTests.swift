import Testing
import Foundation
@testable import Railengine

@Suite("URLBuilder")
struct URLBuilderTests {

    let builder = URLBuilder(
        baseURL: URL(string: "https://test.example.com")!,
        engineId: "eng-1"
    )

    // MARK: Embeddings

    @Test func embeddingsSearchURLBuildsCorrectURL() {
        let url = builder.embeddingsSearchURL()
        #expect(url.absoluteString == "https://test.example.com/api/Engine/eng-1/Embeddings/Search")
    }

    // MARK: Indexing

    @Test func indexingSearchURLBuildsCorrectURL() {
        let url = builder.indexingSearchURL()
        #expect(url.absoluteString == "https://test.example.com/api/Engine/Indexing/Search")
    }

    // MARK: Storage — EventId

    @Test func storageEventIdURLBuildsCorrectURL() {
        let url = builder.storageEventIdURL("evt-abc")
        #expect(url?.absoluteString == "https://test.example.com/api/Engine/eng-1/Storage?EventId=evt-abc")
    }

    // MARK: Storage — CustomerKey

    @Test(
        "storageCustomerKeyURL encodes CustomerKey and pagination",
        arguments: zip(
            [(1, 25), (3, 50), (1, 100)] as [(Int, Int)],
            [
                "https://test.example.com/api/Engine/eng-1/Storage?CustomerKey=user-1&PageNumber=1&PageSize=25",
                "https://test.example.com/api/Engine/eng-1/Storage?CustomerKey=user-1&PageNumber=3&PageSize=50",
                "https://test.example.com/api/Engine/eng-1/Storage?CustomerKey=user-1&PageNumber=1&PageSize=100",
            ]
        )
    )
    func storageCustomerKeyURLBuildsCorrectURL(pagination: (Int, Int), expected: String) {
        let url = builder.storageCustomerKeyURL("user-1", pageNumber: pagination.0, pageSize: pagination.1)
        #expect(url?.absoluteString == expected)
    }

    // MARK: Storage — JsonPath

    @Test(
        "storageJsonPathURL encodes JsonPathQuery and pagination",
        arguments: zip(
            [(1, 25), (2, 50)] as [(Int, Int)],
            [
                "https://test.example.com/api/Engine/eng-1/Storage?JsonPathQuery=$.status:active&PageNumber=1&PageSize=25",
                "https://test.example.com/api/Engine/eng-1/Storage?JsonPathQuery=$.status:active&PageNumber=2&PageSize=50",
            ]
        )
    )
    func storageJsonPathURLBuildsCorrectURL(pagination: (Int, Int), expected: String) {
        let url = builder.storageJsonPathURL("$.status:active", pageNumber: pagination.0, pageSize: pagination.1)
        #expect(url?.absoluteString == expected)
    }

    // MARK: Storage — List

    @Test(
        "storageListURL encodes pagination only",
        arguments: zip(
            [(1, 25), (3, 50)] as [(Int, Int)],
            [
                "https://test.example.com/api/Engine/eng-1/Storage?PageNumber=1&PageSize=25",
                "https://test.example.com/api/Engine/eng-1/Storage?PageNumber=3&PageSize=50",
            ]
        )
    )
    func storageListURLBuildsCorrectURL(pagination: (Int, Int), expected: String) {
        let url = builder.storageListURL(pageNumber: pagination.0, pageSize: pagination.1)
        #expect(url?.absoluteString == expected)
    }

    // MARK: Deletion

    @Test func deleteEventURLBuildsCorrectURL() {
        let url = builder.deleteEventURL("evt-123")
        #expect(url.absoluteString == "https://test.example.com/api/Engine/eng-1/Event/evt-123")
    }
}
