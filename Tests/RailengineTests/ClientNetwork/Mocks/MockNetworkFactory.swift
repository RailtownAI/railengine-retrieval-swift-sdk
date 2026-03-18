//
//  MockNetworkFactory.swift
//  Railengine
//

//

import Foundation
@testable import Railengine

struct MockNetworkFactory: NetworkFactory {

    let mockNetwork: MockClientNetwork

    func clientNetwork(pat: String) -> ClientNetworking {
        mockNetwork
    }
}
