import Testing
import Foundation
@testable import Railengine

@Suite("Railengine.deleteEvent")
struct DeletionTests {

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

    @Test func deleteEventBuildsCorrectURL() async throws {
        try await client.deleteEvent(eventId: "evt-123")

        let url = try #require(mock.capturedURL)
        #expect(url.absoluteString == "https://cndr.railtown.ai/api/Engine/my-engine-id/Event/evt-123")
    }

    // MARK: Success

    @Test func deleteEventSucceeds() async throws {
        try await client.deleteEvent(eventId: "evt-ok")
    }

    // MARK: Error handling

    @Test("throws on network failure", arguments: [
        NetworkError.httpError(statusCode: 404, data: nil),
        NetworkError.missingPAT,
    ])
    func deleteEventThrowsOnNetworkFailure(_ error: NetworkError) async {
        mock.deleteError = error

        await #expect(throws: (any Error).self) {
            try await client.deleteEvent(eventId: "evt-err")
        }
    }
}
