//
//  ClientNetworkDeleteTests.swift
//  Railengine
//
//  Created by Fabricio Sperotto Sffair on 15/03/26.
//

import Testing
import Foundation
@testable import Railengine

@Suite("ClientNetwork delete")
struct ClientNetworkDeleteTests {

    let session: MockURLSession
    let network: ClientNetwork

    init() {
        session = MockURLSession()
        session.statusCode = 200
        session.responseData = Data()
        network = ClientNetwork(pat: "my-secret-pat", session: session)
    }

    @Test func setsAuthorizationHeaderAndDELETEMethod() async throws {
        try await network.delete(url: URL(string: "https://example.com/event/evt-1")!)

        let request = try #require(session.lastRequest)
        #expect(request.httpMethod == "DELETE")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "my-secret-pat")
    }

    @Test func succeedsWithoutReturningData() async throws {
        try await network.delete(url: URL(string: "https://example.com/event/evt-1")!)
    }

    @Test func throwsOnEmptyPAT() async {
        let emptyPat = ClientNetwork(pat: "", session: session)

        await #expect(throws: NetworkError.missingPAT) {
            try await emptyPat.delete(url: URL(string: "https://example.com/event/evt-1")!)
        }
    }

    @Test func throwsHTTPErrorForNon2xx() async {
        session.statusCode = 404
        session.responseData = Data()

        await #expect(throws: NetworkError.self) {
            try await network.delete(url: URL(string: "https://example.com/event/evt-1")!)
        }
    }

    @Test func throwsHTTPErrorWithBodyData() async {
        let errorBody = Data("not found".utf8)
        session.responseData = errorBody
        session.statusCode = 404

        await #expect {
            try await network.delete(url: URL(string: "https://example.com/event/evt-1")!)
        } throws: { error in
            guard case NetworkError.httpError(let code, let data) = error else { return false }
            return code == 404 && data == errorBody
        }
    }

    @Test func throwsInvalidResponseForNonHTTPResponse() async {
        let nonHTTPSession = MockURLSession()
        nonHTTPSession.returnsNonHTTPResponse = true
        let sut = ClientNetwork(pat: "pat", session: nonHTTPSession)

        await #expect(throws: NetworkError.invalidResponse) {
            try await sut.delete(url: URL(string: "https://example.com/event/evt-1")!)
        }
    }

    @Test func throwsRequestFailedOnURLSessionError() async {
        session.error = URLError(.timedOut)

        await #expect {
            try await network.delete(url: URL(string: "https://example.com/event/evt-1")!)
        } throws: { error in
            guard case NetworkError.requestFailed = error else { return false }
            return true
        }
    }
}

