//
//  URLSessioning.swift
//  RailengineIngest
//
//  Created by Fabricio Sperotto Sffair on 10/02/26.
//

import Foundation

protocol URLSessioning: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessioning {}
