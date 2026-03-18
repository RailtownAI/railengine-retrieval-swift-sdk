/// A single page of Hot Storage query results with decoded items.
public struct StoragePage<T: Decodable & Sendable>: Sendable {
    public let items: [T]
    public let totalPages: Int
}

/// A single page of raw Hot Storage documents.
public struct EngineDocumentPage: Sendable {
    public let items: [EngineDocument]
    public let totalPages: Int
}

/// Options for paginated Hot Storage queries.
public struct StorageQueryOptions {
    public let pageNumber: Int
    public let pageSize: Int

    /// - Parameters:
    ///   - pageNumber: First page to fetch (default: 1).
    ///   - pageSize: Documents per page (default: 25, max: 100).
    public init(pageNumber: Int = 1, pageSize: Int = 25) {
        self.pageNumber = pageNumber
        self.pageSize = min(pageSize, 100)
    }
}
