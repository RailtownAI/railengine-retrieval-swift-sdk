//
//  ClientNetworkTests.swift
//  Railengine
//

//

import Testing
import Foundation
@testable import Railengine

// MARK: - ClientNetwork Tests
@Suite("ClientNetwork")
struct ClientNetworkTests {

    let session: MockURLSession
    let network: ClientNetwork

    init() {
        session = MockURLSession()
        session.responseData = Data("[]".utf8)
        session.statusCode = 200
        network = ClientNetwork(pat: "my-secret-pat", session: session)
    }

    @Test func setsAuthorizationHeader() async throws {
        let _: [SearchResult] = try await network.post(
            url: URL(string: "https://example.com/search")!,
            body: EmbeddingsSearchRequest(query: "test", vectorStore: "VS1")
        )

        let request = try #require(session.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "my-secret-pat")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json; charset=utf-8")
        #expect(request.httpMethod == "POST")
    }

    @Test func throwsOnEmptyPAT() async throws {
        let emptyPatNetwork = ClientNetwork(pat: "", session: session)

        await #expect(throws: NetworkError.missingPAT) {
            let _: [SearchResult] = try await emptyPatNetwork.post(
                url: URL(string: "https://example.com/search")!,
                body: EmbeddingsSearchRequest(query: "test", vectorStore: "VS1")
            )
        }
    }
}

