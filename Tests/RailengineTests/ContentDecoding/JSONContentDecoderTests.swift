import Testing
import Foundation
@testable import Railengine

@Suite("JSONContentDecoder")
struct JSONContentDecoderTests {

    private struct Item: Decodable, Sendable, Equatable {
        let id: Int
        let name: String
    }

    let decoder = JSONContentDecoder()

    @Test func decodesValidJSON() throws {
        let result: Item = try decoder.decode(#"{"id": 1, "name": "test"}"#)
        #expect(result == Item(id: 1, name: "test"))
    }

    @Test func throwsDecodingFailedForInvalidJSON() {
        #expect(throws: RailengineError.self) {
            let string = "💇‍♀️"
//            let string = String(UnicodeScalar(UInt8(65)))
            let _: Item = try decoder.decode(string)
        }
    }
    
    @Test func throwsDecodingFailedForSchemaMismatch() {
        #expect(throws: RailengineError.self) {
            let _: Item = try decoder.decode(#"{"id": "wrong-type", "name": "test"}"#)
        }
    }
}
