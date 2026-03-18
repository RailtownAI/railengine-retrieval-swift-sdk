import Foundation

protocol CodableFactory {
    func encoder() -> JSONEncoder
    func decoder() -> JSONDecoder
}

struct DefaultCodableFactory: CodableFactory {
    
    let jsonEncoder: JSONEncoder
    let jsonDecoder: JSONDecoder
    
    init(
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
    
    func encoder() -> JSONEncoder { jsonEncoder }
    func decoder() -> JSONDecoder { jsonDecoder }
}
