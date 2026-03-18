//
//  RailengineErrorTests.swift
//  Railengine
//

//

import Testing
import Foundation
@testable import Railengine


// MARK: - RailengineError Tests
@Suite("RailengineError")
struct RailengineErrorTests {

    @Test(
        "debugDescription contains expected keyword",
        arguments: zip(
            [
                RailengineError.invalidUrl,
                RailengineError.invalidResponse,
                RailengineError.httpError(statusCode: 404, response: "err"),
                RailengineError.missingPAT,
                RailengineError.invalidEventId,
                RailengineError.invalidEngineId,
                RailengineError.encodingFailed(description: nil),
                RailengineError.decodingFailed(description: nil),
                RailengineError.requestFailed(description: nil),
            ],
            [
                "invalid",
                "invalid",
                "404",
                "Personal Access Token",
                "Event id",
                "Engine id",
                "encoded",
                "decoded",
                "failed",
            ]
        )
    )
    func debugDescription(_ error: RailengineError, contains keyword: String) {
        #expect(error.debugDescription.contains(keyword))
    }
}

// MARK: - RailengineError init(NetworkError) Tests
@Suite("RailengineError init from NetworkError")
struct RailengineErrorInitTests {

    @Test func convertsInvalidResponse() {
        #expect(RailengineError(.invalidResponse) == .invalidResponse)
    }

    @Test func convertsHTTPError() {
        #expect(RailengineError(.httpError(statusCode: 404, data: nil)) == .httpError(statusCode: 404, response: ""))
    }

    @Test func httpErrorDropsDataPayload() {
        let withData = RailengineError(.httpError(statusCode: 500, data: Data("body".utf8)))
        let withoutData = RailengineError(.httpError(statusCode: 500, data: nil))
        #expect(withData != withoutData)
    }

    @Test func convertsMissingPAT() {
        #expect(RailengineError(.missingPAT) == .missingPAT)
    }

    @Test func convertsEncodingFailed() {
        #expect(RailengineError(.encodingFailed(error: "encode err")) == .encodingFailed(description: "encode err"))
    }

    @Test func convertsDecodingFailed() {
        #expect(RailengineError(.decodingFailed(error: "decode err")) == .decodingFailed(description: "decode err"))
    }

    @Test func convertsRequestFailed() {
        #expect(RailengineError(.requestFailed(error: "timeout")) == .requestFailed(description: "timeout"))
    }
}
