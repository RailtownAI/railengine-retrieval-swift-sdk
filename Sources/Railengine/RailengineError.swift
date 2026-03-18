import Foundation

extension RailengineError {
    init(_ networkError: NetworkError) {
        switch networkError {
            case .invalidResponse:
                self = .invalidResponse
            case .httpError(let statusCode, let data):
                self = .httpError(statusCode: statusCode, response: String(data: data ?? Data(), encoding: .utf8))
            case .missingPAT:
                self = .missingPAT
            case .encodingFailed(let error):
                self = .encodingFailed(description: error.description)
            case .decodingFailed(let error):
                self = .decodingFailed(description: error.description)
            case .requestFailed(let error):
                self = .requestFailed(description: error.description)
        }
    }
}

public enum RailengineError: Error, Equatable, CustomDebugStringConvertible {
    case invalidUrl
    case invalidResponse
    case httpError(statusCode: Int, response: String?)
    case missingPAT
    case invalidEventId
    case invalidEngineId
    case encodingFailed(description: String?)
    case decodingFailed(description: String?)
    case requestFailed(description: String?)

    public var debugDescription: String {
        switch self {
        case .invalidUrl:
            "The URL provided is invalid or malformed."
        case .invalidResponse:
            "The server returned an invalid or unexpected response."
        case .httpError(let statusCode, let response):
            "The server returned an HTTP error with status code \(statusCode): \(String(describing: response))."
        case .missingPAT:
            "The Personal Access Token (PAT) is missing or empty."
        case .encodingFailed(let description):
            "The request payload could not be encoded to JSON: \(String(describing: description))."
        case .decodingFailed(let description):
            "The response could not be decoded from JSON: \(String(describing: description))."
        case .requestFailed(let description):
            "The network request failed: \(String(describing: description))."
        case .invalidEventId:
            "Event id is invalid or missing."
        case .invalidEngineId:
            "Engine id is invalid or missing."
        }
    }
}
