//
//  MockNetworkFactory.swift
//  Railengine
//
//  Created by Fabricio Sperotto Sffair on 13/02/26.
//

import Foundation
@testable import Railengine

struct MockNetworkFactory: NetworkFactory {

    let mockNetwork: MockClientNetwork

    func clientNetwork(pat: String) -> ClientNetworking {
        mockNetwork
    }
}
