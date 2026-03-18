//
//  ListStorageDocumentsTests.swift
//  Railengine
//

//

import Testing
import Foundation
@testable import Railengine

@Suite("List Storage Documents")
actor ListStorageDocumentsTests {

    let mock: MockClientNetwork
    let client: Railengine

    init() throws {
        mock = MockClientNetwork()
        client = try Railengine(
            pat: "test-pat",
            engineId: "my-engine-id",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: mock),
            contentDecoder: JSONContentDecoder()
        )
    }

    // MARK: URL construction

    @Test func buildsCorrectURLWithDefaultOptions() async throws {
        mock.results = [makePagedResponse(items: [])]

        let _: StoragePage<StorageResult> = try await client.listStorageDocuments()

        let url = try #require(mock.capturedURL)
        #expect(url.absoluteString == "https://cndr.railtown.ai/api/Engine/my-engine-id/Storage?PageNumber=1&PageSize=25")
    }

    @Test func buildsCorrectURLWithCustomOptions() async throws {
        mock.results = [makePagedResponse(items: [])]
        let options = StorageQueryOptions(pageNumber: 3, pageSize: 50)

        let _: StoragePage<StorageResult> = try await client.listStorageDocuments(options: options)

        let url = try #require(mock.capturedURL)
        #expect(url.absoluteString == "https://cndr.railtown.ai/api/Engine/my-engine-id/Storage?PageNumber=3&PageSize=50")
    }

    // MARK: Typed overload

    @Test func typedOverloadReturnsDecodedItemsAndTotalPages() async throws {
        mock.results = [makePagedResponse(items: [
            makePagedItem(content: #"{"id": 1}"#),
            makePagedItem(content: #"{"id": 2}"#)
        ], totalPages: 5)]

        let page: StoragePage<StorageResult> = try await client.listStorageDocuments()

        #expect(page.items == [StorageResult(id: 1), StorageResult(id: 2)])
        #expect(page.totalPages == 5)
    }

    @Test func typedOverloadSkipsItemsWithWrongSchema() async throws {
        mock.results = [makePagedResponse(items: [
            makePagedItem(content: #"{"id": 1}"#),
            makePagedItem(content: #"{"wrong_field": "no id"}"#),
            makePagedItem(content: #"{"id": 3}"#)
        ])]

        let page: StoragePage<StorageResult> = try await client.listStorageDocuments()

        #expect(page.items == [StorageResult(id: 1), StorageResult(id: 3)])
    }

    // MARK: Raw overload

    @Test func rawOverloadReturnsEngineDocumentsAndTotalPages() async throws {
        mock.results = [makePagedResponse(items: [
            makePagedItem(content: #"{"id": 1}"#, eventId: "evt-list-1"),
            makePagedItem(content: #"{"id": 2}"#, eventId: "evt-list-2")
        ], totalPages: 2)]

        let page: EngineDocumentPage = try await client.listStorageDocuments()

        #expect(page.items.count == 2)
        #expect(page.items[0].eventId == "evt-list-1")
        #expect(page.items[0].engineDocumentId == nil)
        #expect(page.items[1].eventId == "evt-list-2")
        #expect(page.totalPages == 2)
    }

    // MARK: Guard failures

    @Test func throwsInvalidUrlWhenURLBuilderReturnsNil() async {
        let nilURLClient = try! Railengine(
            pat: "test-pat",
            engineId: "my-engine-id",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: mock),
            urlBuilder: MockURLBuilder(storageURLsReturnNil: true),
            contentDecoder: JSONContentDecoder()
        )

        await #expect(throws: RailengineError.invalidUrl) {
            let _: StoragePage<StorageResult> = try await nilURLClient.listStorageDocuments()
        }
    }

    // MARK: Error handling

    @Test func typedOverloadThrowsOnNetworkError() async {
        mock.error = .httpError(statusCode: 500, data: nil)

        await #expect(throws: (any Error).self) {
            let _: StoragePage<StorageResult> = try await client.listStorageDocuments()
        }
    }

    @Test func rawOverloadThrowsOnNetworkError() async {
        mock.error = .httpError(statusCode: 500, data: nil)

        await #expect(throws: (any Error).self) {
            let _: EngineDocumentPage = try await client.listStorageDocuments()
        }
    }
}
