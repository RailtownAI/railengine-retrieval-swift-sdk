import Foundation

protocol NetworkFactory {
    func clientNetwork(pat: String) -> ClientNetworking
}

class RetrievalClientFactory: NetworkFactory {

    private init() {}

    static var shared: RetrievalClientFactory { RetrievalClientFactory() }

    func clientNetwork(pat: String) -> ClientNetworking {
        ClientNetwork(pat: pat)
    }
}
