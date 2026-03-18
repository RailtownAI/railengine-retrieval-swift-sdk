import Foundation

enum NetworkError: Error, Equatable {
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case missingPAT
    case encodingFailed(error: String)
    case decodingFailed(error: String)
    case requestFailed(error: String)
}
