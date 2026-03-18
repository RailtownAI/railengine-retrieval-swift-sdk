//
//  RetrievalClientFactoryTests.swift
//  Railengine
//

//

import Testing
import Foundation
@testable import Railengine

// MARK: - NetworkFactory Tests

@Suite("RetrievalClientFactory")
struct RetrievalClientFactoryTests {

    @Test func createsClientNetwork() {
        let factory = RetrievalClientFactory.shared
        let network = factory.clientNetwork(pat: "test-pat")
        #expect(network is ClientNetwork)
    }
}

