import Foundation

protocol ClientNetworking: Actor {
    func get<Response: Decodable>(url: URL) async throws(NetworkError) -> Response
    func post<Request: Encodable, Response: Decodable>(
        url: URL,
        body: Request
    ) async throws(NetworkError) -> Response
    func delete(url: URL) async throws(NetworkError)
}

actor ClientNetwork: ClientNetworking {

    private let session: URLSessioning
    private let pat: String
    private let codableFactory: CodableFactory

    init(
        pat: String,
        session: URLSessioning = URLSession.shared,
        codableFactory: CodableFactory = DefaultCodableFactory()
    ) {
        self.pat = pat
        self.session = session
        self.codableFactory = codableFactory
    }

    func get<Response: Decodable>(url: URL) async throws(NetworkError) -> Response {
        let request = try buildRequest(url: url, method: .get)
        let (data, _) = try await data(for: request)
        return try decode(data)
    }

    func post<Request: Encodable, Response: Decodable>(
        url: URL,
        body: Request
    ) async throws(NetworkError) -> Response {
        let request = try buildRequest(url: url, method: .post, payload: body)
        let (data, _) = try await data(for: request)
        return try decode(data)
    }

    func delete(url: URL) async throws(NetworkError) {
        let request = try buildRequest(url: url, method: .delete)
        _ = try await data(for: request)
    }

}

private extension ClientNetwork {

    // MARK: - Request Building
    func buildRequest(url: URL, method: HTTPMethod) throws(NetworkError) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        guard !pat.isEmpty else {
            throw NetworkError.missingPAT
        }
        request.setValue(pat, forHTTPHeaderField: "Authorization")

        return request
    }

    func buildRequest<T: Encodable>(url: URL, method: HTTPMethod, payload: T) throws(NetworkError) -> URLRequest {
        var request = try buildRequest(url: url, method: method)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try codableFactory.encoder().encode(payload)
        } catch {
            throw NetworkError.encodingFailed(error: error.localizedDescription)
        }
        return request
    }

    // MARK: - Response Handling
    func data(for request: URLRequest) async throws(NetworkError) -> (Data, URLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200...299).contains(http.statusCode) else {
                throw NetworkError.httpError(statusCode: http.statusCode, data: data.isEmpty ? nil : data)
            }
            return (data, response)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error: error.localizedDescription)
        }
    }

    func decode<T: Decodable>(_ data: Data) throws(NetworkError) -> T {
        do {
            return try codableFactory.decoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error: "\(error)")
        }
    }
}
