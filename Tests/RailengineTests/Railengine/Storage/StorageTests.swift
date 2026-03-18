import Testing
import Foundation
@testable import Railengine

// MARK: - Test Helpers
struct StorageResult: Decodable, Equatable {
    let id: Int
}

func makeEngineDocument(content: String, engineDocumentId: String? = "doc-1") -> EngineDocument {
    EngineDocument(
        engineDocumentId: engineDocumentId,
        eventId: "evt-1",
        projectId: "proj-1",
        engineId: "eng-1",
        customerKey: "cust-1",
        content: content,
        version: 1,
        dateCreated: "2026-02-21T00:00:00Z",
        dateUpdated: nil
    )
}

func makePagedResponse(items: [StoragePagedItem], totalPages: Int = 1) -> StoragePagedResponse {
    StoragePagedResponse(items: items, totalPages: totalPages)
}

func makePagedItem(content: String = #"{"id": 1}"#, eventId: String = "evt-1") -> StoragePagedItem {
    StoragePagedItem(
        eventId: eventId,
        projectId: "proj-1",
        engineId: "eng-1",
        customerKey: "cust-1",
        content: content,
        version: 1,
        dateCreated: "2026-02-21T00:00:00Z",
        dateUpdated: nil
    )
}

// MARK: - Storage Tests

@Suite("Storage")
actor StorageTests {

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

    @Test func buildsCorrectURLWithEventIdQueryParam() async throws {
        mock.result = makeEngineDocument(content: #"{"id": 1}"#) as Any
        let _: StorageResult? = try await client.getStorageDocumentByEventId(eventId: "evt-123")

        let url = try #require(mock.capturedURL)
        #expect(url.absoluteString == "https://cndr.railtown.ai/api/Engine/my-engine-id/Storage?EventId=evt-123")
    }

    // MARK: Typed overload

    @Test func decodesContentIntoTypedResult() async throws {
        mock.result = makeEngineDocument(content: #"{"id": 42}"#) as Any

        let result: StorageResult? = try await client.getStorageDocumentByEventId(eventId: "evt-42")

        #expect(result == StorageResult(id: 42))
    }

    @Test func returnsNilWhenContentDoesNotMatchSchema() async throws {
        mock.result = makeEngineDocument(content: #"{"wrong_field": "no id here"}"#) as Any

        let result: StorageResult? = try await client.getStorageDocumentByEventId(eventId: "evt-bad")

        #expect(result == nil)
    }

    // MARK: Raw overload

    @Test func returnsFullEngineDocumentWhenNoTypeSpecified() async throws {
        let document = makeEngineDocument(content: #"{"id": 42}"#)
        mock.result = document as Any

        let result: EngineDocument? = try await client.getStorageDocumentByEventId(eventId: "evt-42")

        #expect(result?.engineDocumentId == "doc-1")
        #expect(result?.eventId == "evt-1")
        #expect(result?.content == #"{"id": 42}"#)
    }


    // MARK: Nil document

    @Test func returnsNilWhenDocumentNotFound() async throws {
        mock.returnsNilGetResult = true

        let result: EngineDocument? = try await client.getStorageDocumentByEventId(eventId: "evt-missing")

        #expect(result == nil)
    }

    @Test func typedOverloadReturnsNilWhenDocumentNotFound() async throws {
        mock.returnsNilGetResult = true

        let result: StorageResult? = try await client.getStorageDocumentByEventId(eventId: "evt-missing")

        #expect(result == nil)
    }

    // MARK: Guard failures

    @Test func throwsInvalidEventIdWhenURLBuilderReturnsNil() async {
        let nilURLClient = try! Railengine(
            pat: "test-pat",
            engineId: "my-engine-id",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: mock),
            urlBuilder: MockURLBuilder(storageURLsReturnNil: true),
            contentDecoder: JSONContentDecoder()
        )

        await #expect(throws: RailengineError.invalidEventId) {
            let _: EngineDocument? = try await nilURLClient.getStorageDocumentByEventId(eventId: "evt-1")
        }
    }

    // MARK: Error handling

    @Test func throwsOnNetworkError() async {
        mock.error = .httpError(statusCode: 404, data: nil)

        await #expect(throws: (any Error).self) {
            let _: StorageResult? = try await client.getStorageDocumentByEventId(eventId: "evt-err")
        }
    }

    @Test func rawOverloadThrowsOnNetworkError() async {
        mock.error = .httpError(statusCode: 404, data: nil)

        await #expect(throws: (any Error).self) {
            let _: EngineDocument? = try await client.getStorageDocumentByEventId(eventId: "evt-err")
        }
    }
}
