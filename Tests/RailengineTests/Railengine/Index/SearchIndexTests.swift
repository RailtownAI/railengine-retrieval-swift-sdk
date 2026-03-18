//
//  SearchIndexTests.swift
//  Railengine
//

//

import Testing
import Foundation
@testable import Railengine

// MARK: - Railengine.searchIndex Tests
@Suite("Railengine.searchIndex")
struct SearchIndexTests {

    let mock: MockClientNetwork
    let client: Railengine

    init() throws {
        mock = MockClientNetwork()
        mock.result = IndexSearchResponse(value: []) as Any
        client = try Railengine(
            pat: "test-pat",
            engineId: "my-engine-id",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: mock),
            contentDecoder: JSONContentDecoder()
        )
    }

    // MARK: URL construction

    @Test func searchIndexBuildsCorrectURL() async throws {
        let _: [IndexDocument] = try await client.searchIndex(query: IndexQuery(search: "*"))

        let url = try #require(mock.capturedURL)
        #expect(url.absoluteString == "https://cndr.railtown.ai/api/Engine/Indexing/Search")
    }

    // MARK: Request body

    @Test func searchIndexEncodesEngineIdAndQueryInRequestBody() async throws {
        let _: [IndexDocument] = try await client.searchIndex(
            query: IndexQuery(search: "swift", queryType: .full, searchMode: .all)
        )

        let body = try #require(mock.capturedBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let queryJson = json?["Query"] as? [String: Any]
        #expect(json?["EngineId"] as? String == "my-engine-id")
        #expect(queryJson?["search"] as? String == "swift")
        #expect(queryJson?["queryType"] as? String == "full")
        #expect(queryJson?["searchMode"] as? String == "all")
    }

    // MARK: Typed overload

    @Test func searchIndexDecodesBodyIntoTypedResults() async throws {
        mock.result = IndexSearchResponse(value: [
            makeIndexDocument(body: #"{"id": 1, "text": "hello"}"#),
            makeIndexDocument(body: #"{"id": 2, "text": "world"}"#),
        ]) as Any

        let results: [SearchResult] = try await client.searchIndex(query: IndexQuery(search: "*"))

        #expect(results.count == 2)
        #expect(results[0] == SearchResult(id: 1, text: "hello"))
        #expect(results[1] == SearchResult(id: 2, text: "world"))
    }

    @Test(
        "typed overload skips undecodable items",
        arguments: [
            nil as String?,
            "not json",
            #"{"wrong_field": "no id or text here"}"#,
        ]
    )
    func searchIndexTypedSkipsUndecodableItems(badBody: String?) async throws {
        mock.result = IndexSearchResponse(value: [
            makeIndexDocument(body: #"{"id": 1, "text": "valid"}"#),
            makeIndexDocument(body: badBody),
            makeIndexDocument(body: #"{"id": 3, "text": "also valid"}"#),
        ]) as Any

        let results: [SearchResult] = try await client.searchIndex(query: IndexQuery(search: "*"))

        #expect(results.count == 2)
        #expect(results[0] == SearchResult(id: 1, text: "valid"))
        #expect(results[1] == SearchResult(id: 3, text: "also valid"))
    }

    @Test(
        "typed overload manages Body in select",
        arguments: zip(
            ["SearchableContent1", "SearchableContent1, Body", nil] as [String?],
            ["SearchableContent1, Body", "SearchableContent1, Body", nil] as [String?]
        )
    )
    func searchIndexTypedManagesBodyInSelect(input: String?, expected: String?) async throws {
        let query = IndexQuery(search: "*", select: input)
        let _: [SearchResult] = try await client.searchIndex(query: query)

        let body = try #require(mock.capturedBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let queryJson = json?["Query"] as? [String: Any]
        #expect(queryJson?["select"] as? String == expected)
    }

    // MARK: Raw overload

    @Test func searchIndexReturnsFullEnvelopeWhenNoTypeSpecified() async throws {
        mock.result = IndexSearchResponse(value: [
            makeIndexDocument(eventId: "doc-1", body: #"{"id": 1}"#),
            makeIndexDocument(eventId: "doc-2", body: #"{"id": 2}"#),
        ]) as Any

        let results: [IndexDocument] = try await client.searchIndex(query: IndexQuery(search: "*"))

        #expect(results.count == 2)
        #expect(results[0].eventId == "doc-1")
        #expect(results[1].eventId == "doc-2")
    }

    @Test func searchIndexRawDoesNotDecodeBody() async throws {
        mock.result = IndexSearchResponse(value: [
            makeIndexDocument(body: #"{"id": 1, "text": "hello"}"#),
        ]) as Any

        let results: [IndexDocument] = try await client.searchIndex(query: IndexQuery(search: "*"))

        #expect(results[0].body == #"{"id": 1, "text": "hello"}"#)
    }

    @Test func searchIndexRawDoesNotAppendBodyToSelect() async throws {
        let query = IndexQuery(search: "*", select: "SearchableContent1")
        let _: [IndexDocument] = try await client.searchIndex(query: query)

        let body = try #require(mock.capturedBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let queryJson = json?["Query"] as? [String: Any]
        #expect(queryJson?["select"] as? String == "SearchableContent1")
    }

    // MARK: Error handling

    @Test(
        "throws on network failure",
        arguments: [
            NetworkError.httpError(statusCode: 401, data: nil),
            NetworkError.missingPAT,
        ]
    )
    func searchIndexThrowsOnNetworkFailure(_ error: NetworkError) async {
        mock.error = error

        await #expect(throws: (any Error).self) {
            let _: [IndexDocument] = try await client.searchIndex(query: IndexQuery(search: "*"))
        }
    }
}

private extension SearchIndexTests {
    func makeIndexDocument(eventId: String? = nil, body: String? = nil) -> IndexDocument {
        var dict: [String: String] = [:]
        if let eventId { dict["eventId"] = eventId }
        if let body { dict["body"] = body }
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(IndexDocument.self, from: data)
    }
}
