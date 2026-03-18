//
//  RailengineTests.swift
//  Railengine
//
//  Created by Fabricio Sperotto Sffair on 15/03/26.
//

import Testing
import Foundation
@testable import Railengine

@Suite("SearchVectoreStoreTests")
struct SearchVectoreStoreTests {

    let mock: MockClientNetwork
    let client: Railengine

    init() throws {
        mock = MockClientNetwork()
        mock.result = [SearchDocument]()
        client = try Railengine(
            pat: "test-pat",
            engineId: "my-engine-id",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: mock),
            contentDecoder: JSONContentDecoder()
        )
    }

    // MARK: URL construction

    @Test func searchVectorStoreBuildsCorrectURL() async throws {
        let _: [SearchResult] = try await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "test"
        )

        let url = try #require(mock.capturedURL)
        #expect(url.absoluteString == "https://cndr.railtown.ai/api/Engine/my-engine-id/Embeddings/Search")
    }

    @Test func searchVectorStoreBuildsCorrectURLWithCustomApiUrl() async throws {
        let customMock = MockClientNetwork()
        customMock.result = [SearchDocument]() as Any
        let customClient = try Railengine(
            pat: "test-pat",
            engineId: "engine-1",
            apiUrl: "https://custom.example.com/api",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: customMock),
            contentDecoder: JSONContentDecoder()
        )

        let _: [SearchResult] = try await customClient.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "test"
        )

        let url = try #require(customMock.capturedURL)
        #expect(url.absoluteString == "https://custom.example.com/api/Engine/engine-1/Embeddings/Search")
    }

    // MARK: Request body

    @Test func searchVectorStoreEncodesRequestBody() async throws {
        let _: [SearchResult] = try await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "apple"
        )

        let body = try #require(mock.capturedBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["Query"] as? String == "apple")
        #expect(json?["VectorStore"] as? String == "VectorStore1")
    }

    // MARK: Typed overload

    @Test func searchVectorStoreDecodesContentIntoTypedResults() async throws {
        mock.result = makeSearchDocuments([
            #"{"id": 1, "text": "hello"}"#,
            #"{"id": 2, "text": "world"}"#,
        ]) as Any

        let results: [SearchResult] = try await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "test"
        )

        #expect(results.count == 2)
        #expect(results[0] == SearchResult(id: 1, text: "hello"))
        #expect(results[1] == SearchResult(id: 2, text: "world"))
    }

    @Test(
        "typed overload skips undecodable items",
        arguments: [
            #"not json"#,
            #"{"wrong_field": "no id or text here"}"#,
        ]
    )
    func searchVectorStoreSkipsUndecodableItems(badContent: String) async throws {
        mock.result = makeSearchDocuments([
            #"{"id": 1, "text": "valid"}"#,
            badContent,
            #"{"id": 3, "text": "also valid"}"#,
        ]) as Any

        let results: [SearchResult] = try await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "test"
        )

        #expect(results.count == 2)
        #expect(results[0] == SearchResult(id: 1, text: "valid"))
        #expect(results[1] == SearchResult(id: 3, text: "also valid"))
    }

    // MARK: Raw overload

    @Test func searchVectorStoreReturnsFullEnvelopeWhenNoTypeSpecified() async throws {
        mock.result = [
            SearchDocument(eventId: "abc-1", projectId: "p", engineId: "e", customerKey: "c", score: 0.9, content: #"{"food_name": "apple"}"#),
            SearchDocument(eventId: "abc-2", projectId: "p", engineId: "e", customerKey: "c", score: 0.7, content: #"{"food_name": "banana"}"#),
        ] as Any

        let results: [SearchDocument] = try await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "fruit"
        )

        #expect(results.count == 2)
        #expect(results[0].eventId == "abc-1")
        #expect(results[0].score == 0.9)
        #expect(results[0].content == #"{"food_name": "apple"}"#)
        #expect(results[1].eventId == "abc-2")
    }

    @Test func searchVectorStoreRawDoesNotDecodeContent() async throws {
        mock.result = [
            SearchDocument(eventId: "abc-1", projectId: "p", engineId: "e", customerKey: "c", score: 0.9, content: #"{"food_name": "apple"}"#),
        ] as Any

        let results: [SearchDocument] = try await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "fruit"
        )

        // Content is a raw string, not a decoded object
        #expect(results[0].content == #"{"food_name": "apple"}"#)
    }

    // MARK: Error handling

    @Test(
        "throws on network failure",
        arguments: [
            NetworkError.httpError(statusCode: 401, data: nil),
            NetworkError.missingPAT,
        ]
    )
    func searchVectorStoreThrowsOnNetworkFailure(_ error: NetworkError) async {
        mock.error = error

        await #expect(throws: (any Error).self) {
            let _: [SearchResult] = try await client.searchVectorStore(
                vectorStore: .VectorStore1,
                query: "test"
            )
        }
    }
}

private extension SearchVectoreStoreTests {
    
    func makeSearchDocuments(_ contents: [String]) -> [SearchDocument] {
        contents.map { content in
            SearchDocument(
                eventId: "test-event-id",
                projectId: "test-project-id",
                engineId: "test-engine-id",
                customerKey: "test-customer-key",
                score: 0.9,
                content: content
            )
        }
    }
}
