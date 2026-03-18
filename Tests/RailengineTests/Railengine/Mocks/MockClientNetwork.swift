//
//  MockClientNetwork.swift
//  Railengine
//
//  Created by Fabricio Sperotto Sffair on 13/02/26.
//

import Foundation
@testable import Railengine

actor MockClientNetwork: ClientNetworking {

    nonisolated(unsafe) var capturedURL: URL?
    nonisolated(unsafe) var capturedBody: Data?
    nonisolated(unsafe) var result: Any?
    nonisolated(unsafe) var error: NetworkError?
    nonisolated(unsafe) var deleteError: NetworkError?

    /// Provide sequential responses for multiple calls. If non-empty,
    /// each call consumes the next entry; when exhausted the last entry repeats.
    nonisolated(unsafe) var results: [Any] = []
    nonisolated(unsafe) var callCount: Int = 0
    nonisolated(unsafe) var returnsNilGetResult: Bool = false

    func get<Response: Decodable>(url: URL) async throws(NetworkError) -> Response {
        capturedURL = url
        if let error { throw error }
        if returnsNilGetResult {
            // Decode JSON `null` — only succeeds when Response is an Optional type.
            if let nilValue = try? JSONDecoder().decode(Response.self, from: Data("null".utf8)) {
                return nilValue
            }
        }
        let current: Any?
        if results.isEmpty {
            current = result
        } else {
            let index = min(callCount, results.count - 1)
            current = results[index]
        }
        callCount += 1
        guard let r = current as? Response else {
            throw NetworkError.decodingFailed(error: "No mock result configured")
        }
        return r
    }

    func post<Request: Encodable, Response: Decodable>(
        url: URL,
        body: Request
    ) async throws(NetworkError) -> Response {
        capturedURL = url
        capturedBody = try? JSONEncoder().encode(body)

        if let error {
            throw error
        }

        guard let result = result as? Response else {
            throw NetworkError.decodingFailed(error: "No mock result configured")
        }
        return result
    }

    func delete(url: URL) async throws(NetworkError) {
        capturedURL = url
        if let deleteError { throw deleteError }
    }

    func fetchCustomerKeyPage(base: URL, engine: String, customerKey: String, pageNumber: Int, pageSize: Int) async throws(NetworkError) -> StoragePagedResponse {
        guard let url = Self.buildStorageURL(base: base, engine: engine, customerKey: customerKey, pageNumber: pageNumber, pageSize: pageSize) else {
            throw NetworkError.requestFailed(error: "Could not construct URL")
        }
        return try await get(url: url)
    }

    private static func buildStorageURL(base: URL, engine: String, customerKey: String, pageNumber: Int, pageSize: Int) -> URL? {
        var components = URLComponents(
            url: base
                .appendingPathComponent("api")
                .appendingPathComponent("Engine")
                .appendingPathComponent(engine)
                .appendingPathComponent("Storage"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "CustomerKey", value: customerKey),
            URLQueryItem(name: "PageNumber", value: "\(pageNumber)"),
            URLQueryItem(name: "PageSize", value: "\(pageSize)")
        ]
        return components?.url
    }


}
