//
//  ClientNetworkGetTests.swift
//  Railengine
//
//  Created by Fabricio Sperotto Sffair on 15/03/26.
//

import Testing
import Foundation
@testable import Railengine

@Suite("ClientNetwork get")
struct ClientNetworkGetTests {

    let session: MockURLSession
    let network: ClientNetwork

    init() {
        session = MockURLSession()
        session.statusCode = 200
        session.responseData = Data(Self.engineDocumentJSON().utf8)
        network = ClientNetwork(pat: "my-secret-pat", session: session)
    }

    @Test func setsAuthorizationHeaderAndGETMethod() async throws {
        let _: EngineDocument = try await network.get(url: URL(string: "https://example.com/storage")!)

        let request = try #require(session.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "my-secret-pat")
    }

    @Test func throwsOnEmptyPAT() async {
        let emptyPat = ClientNetwork(pat: "", session: session)

        await #expect(throws: NetworkError.missingPAT) {
            let _: EngineDocument = try await emptyPat.get(url: URL(string: "https://example.com/storage")!)
        }
    }

    @Test func decodesResponse() async throws {
        let result: EngineDocument = try await network.get(url: URL(string: "https://example.com/storage")!)

        #expect(result.eventId == "evt-1")
        #expect(result.content == "{}")
    }

    @Test func throwsDecodingFailedOnInvalidJSON() async {
        session.responseData = Data("not valid json".utf8)

        await #expect {
            let _: EngineDocument = try await network.get(url: URL(string: "https://example.com/storage")!)
        } throws: { error in
            guard case NetworkError.decodingFailed = error else { return false }
            return true
        }
    }

    @Test func throwsHTTPErrorForNon2xx() async {
        session.statusCode = 404
        session.responseData = Data()

        await #expect(throws: NetworkError.self) {
            let _: EngineDocument = try await network.get(url: URL(string: "https://example.com/storage")!)
        }
    }

    @Test func throwsInvalidResponseForNonHTTPResponse() async {
        let nonHTTPSession = MockURLSession()
        nonHTTPSession.returnsNonHTTPResponse = true
        let sut = ClientNetwork(pat: "pat", session: nonHTTPSession)

        await #expect(throws: NetworkError.invalidResponse) {
            let _: EngineDocument = try await sut.get(url: URL(string: "https://example.com/storage")!)
        }
    }

    @Test func throwsRequestFailedOnURLSessionError() async {
        session.error = URLError(.timedOut)

        await #expect {
            let _: EngineDocument = try await network.get(url: URL(string: "https://example.com/storage")!)
        } throws: { error in
            guard case NetworkError.requestFailed = error else { return false }
            return true
        }
    }

    @Test func throwsHTTPErrorWithBodyData() async {
        let errorBody = Data("forbidden".utf8)
        session.responseData = errorBody
        session.statusCode = 403

        await #expect {
            let _: EngineDocument = try await network.get(url: URL(string: "https://example.com/storage")!)
        } throws: { error in
            guard case NetworkError.httpError(let code, let data) = error else { return false }
            return code == 403 && data == errorBody
        }
    }
}

private extension ClientNetworkGetTests {
    static func engineDocumentJSON(eventId: String = "evt-1") -> String {
    """
    {"eventId":"\(eventId)","projectId":"proj-1","engineId":"eng-1","customerKey":"cust-1","content":"{}","version":1,"dateCreated":"2026-01-01T00:00:00Z"}
    """
    }
}
