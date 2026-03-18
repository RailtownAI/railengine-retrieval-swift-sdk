//
//  ClientNetworkTests 2.swift
//  Railengine
//

//

import Testing
import Foundation
@testable import Railengine

@Suite("ClientNetwork Post")
struct ClientNetworkPostTests {

    let session: MockURLSession
    let network: ClientNetwork

    init() {
        session = MockURLSession()
        session.responseData = Data("[]".utf8)
        session.statusCode = 200
        network = ClientNetwork(pat: "my-secret-pat", session: session)
    }

    @Test("post throws httpError for non-2xx status", arguments: 400...599)
    func throwsOnHTTPError(statusCode: Int) async throws {
        let errorSession = MockURLSession()
        session.responseData = Data()
        session.statusCode = statusCode
        let errorNetwork = ClientNetwork(pat: "pat", session: errorSession)

        await #expect(throws: NetworkError.self) {
            let _: [SearchResult] = try await errorNetwork.post(
                url: URL(string: "https://example.com/search")!,
                body: EmbeddingsSearchRequest(query: "test", vectorStore: "VS1")
            )
        }
    }

    @Test("post throws invalidResponse for non-HTTP response")
    func postThrowsForNonHTTPResponse() async {
        let session = MockURLSession()
        session.returnsNonHTTPResponse = true
        let sut = ClientNetwork(pat: "path", session: session)

        await #expect(throws: NetworkError.invalidResponse) {
            let _: [SearchResult] = try await sut.post(url: URL(string: "https://example.com/search")!, body: ["key": "value"])
        }
    }


    @Test func throwsEncodingFailedWhenPayloadCannotBeEncoded() async {
        struct Unencodable: Encodable {
            func encode(to encoder: Encoder) throws {
                throw EncodingError.invalidValue(
                    "bad",
                    .init(codingPath: [], debugDescription: "forced encoding failure")
                )
            }
        }

        await #expect {
            let _: [SearchResult] = try await network.post(
                url: URL(string: "https://example.com/search")!,
                body: Unencodable()
            )
        } throws: { error in
            guard case NetworkError.encodingFailed = error else { return false }
            return true
        }
    }

    @Test func throwsHTTPErrorWithBodyDataOnNon2xxResponse() async {
        let errorBody = Data("not authorized".utf8)
        let errorSession = MockURLSession()
        errorSession.responseData = errorBody
        errorSession.statusCode = 401
        let sut = ClientNetwork(pat: "pat", session: errorSession)

        await #expect {
            let _: [SearchResult] = try await sut.post(
                url: URL(string: "https://example.com/search")!,
                body: EmbeddingsSearchRequest(query: "test", vectorStore: "VS1")
            )
        } throws: { error in
            guard case NetworkError.httpError(let code, let data) = error else { return false }
            return code == 401 && data == errorBody
        }
    }

    @Test func throwsRequestFailedOnURLSessionError() async {
        session.error = URLError(.timedOut)

        await #expect {
            let _: [SearchResult] = try await network.post(
                url: URL(string: "https://example.com/search")!,
                body: EmbeddingsSearchRequest(query: "test", vectorStore: "VS1")
            )
        } throws: { error in
            guard case NetworkError.requestFailed = error else { return false }
            return true
        }
    }

    @Test func decodesResponse() async throws {
        let json = """
        [{"id": 1, "text": "result"}]
        """
        let jsonSession = MockURLSession()
        jsonSession.responseData = Data(json.utf8)
        jsonSession.statusCode = 200
        let jsonNetwork = ClientNetwork(pat: "pat", session: jsonSession)

        let results: [SearchResult] = try await jsonNetwork.post(
            url: URL(string: "https://example.com/search")!,
            body: EmbeddingsSearchRequest(query: "test", vectorStore: "VS1")
        )

        #expect(results.count == 1)
        #expect(results[0] == SearchResult(id: 1, text: "result"))
    }
}
