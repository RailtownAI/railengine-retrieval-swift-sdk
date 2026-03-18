//
//  MockURLSession.swift
//  Railengine
//
//  Created by Fabricio Sperotto Sffair on 13/02/26.
//

import Foundation
@testable import Railengine

// MARK: - Mock URLSession

final class MockURLSession: URLSessioning, @unchecked Sendable {

    var lastRequest: URLRequest?
    var responseData: Data = Data()
    var statusCode: Int = 200
    var error: Error?
    var returnsNonHTTPResponse = false

    /// Sequential (data, statusCode) pairs consumed in order; last entry repeats when exhausted.
    /// When empty, falls back to `responseData` / `statusCode`.
    var responses: [(data: Data, statusCode: Int)] = []
    private(set) var callCount: Int = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error { throw error }
        if returnsNonHTTPResponse {
            return (responseData, URLResponse())
        }

        let data: Data
        let code: Int
        if !responses.isEmpty {
            let index = min(callCount, responses.count - 1)
            data = responses[index].data
            code = responses[index].statusCode
        } else {
            data = responseData
            code = statusCode
        }
        callCount += 1

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
}
