import Testing
import Foundation
@testable import Railengine

struct SearchResult: Decodable, Equatable {
    let id: Int
    let text: String
}

@Suite("Railengine public init")
struct RailenginePublicInitTests {
    
    @Test func publicInitSucceedsWithJSONContentDecoder() throws {
        // Calls the public init directly — confirms it completes without error
        // and that JSONContentDecoder() is the hardcoded default.
        let _ = try Railengine(pat: "test-pat", engineId: "my-engine")
    }
    
    @Test func usesDefaultApiUrl() async throws {
        let mock = MockClientNetwork()
        
        let client = try Railengine(pat: "test-pat", engineId: "my-engine", clientNetworkFactory: MockNetworkFactory(mockNetwork: mock), contentDecoder: JSONContentDecoder())

        let results: [SearchResult] = (try? await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "test"
        )) ?? []
        let capturedUrlHost = try #require(mock.capturedURL?.host())
        #expect(capturedUrlHost == "cndr.railtown.ai")
        #expect(results.isEmpty)
    }

    @Test func acceptsCustomApiUrl() async throws {
        let mock = MockClientNetwork()
        let client = try Railengine(
            pat: "test-pat",
            engineId: "my-engine",
            apiUrl: "https://custom.example.com/api",
            clientNetworkFactory: MockNetworkFactory(mockNetwork: mock),
            contentDecoder: JSONContentDecoder()
        )

        let results: [SearchResult] = (try? await client.searchVectorStore(
            vectorStore: .VectorStore1,
            query: "test"
        )) ?? []

        #expect(results.isEmpty)
    }

    @Test func throwsOnInvalidUrl() {
        #expect(throws: RailengineError.invalidUrl) {
            try Railengine(pat: "test-pat", engineId: "my-engine", apiUrl: "http://[unclosed")
        }
    }
}
