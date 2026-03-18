import Foundation

public enum VectorStore: String {
    case VectorStore1
    case VectorStore2
    case VectorStore3
}

public actor Railengine {

    private static var defaultApiUrl: String { "https://cndr.railtown.ai" }

    private let engineId: String
    private let baseURL: URL
    nonisolated private let clientNetwork: ClientNetworking
    private let contentDecoder: JSONContentDecoder
    private let urlBuilder: URLBuilding

    public init(pat: String, engineId: String, apiUrl: String? = nil) throws {
        try self.init(
            pat: pat,
            engineId: engineId,
            apiUrl: apiUrl,
            clientNetworkFactory: RetrievalClientFactory.shared,
            contentDecoder: JSONContentDecoder()
        )
    }

    init(
        pat: String,
        engineId: String,
        apiUrl: String? = nil,
        clientNetworkFactory: NetworkFactory,
        urlBuilder: URLBuilding? = nil,
        contentDecoder: JSONContentDecoder
    ) throws(RailengineError) {
        self.engineId = engineId
        self.contentDecoder = contentDecoder

        let rawUrl = apiUrl ?? Self.defaultApiUrl
        let normalizedUrl = rawUrl.hasSuffix("/api") ? String(rawUrl.dropLast(4)) : rawUrl
        guard let url = URL(string: normalizedUrl) else {
            throw RailengineError.invalidUrl
        }
        self.baseURL = url

        self.clientNetwork = clientNetworkFactory.clientNetwork(pat: pat)
        self.urlBuilder = urlBuilder ?? URLBuilder(baseURL: url, engineId: engineId)
    }

    // MARK: - Embedding
    /// Searches a vector store and decodes each result's Content field into `T`.
    /// Items whose Content cannot be decoded into `T` are silently skipped.
    public func searchVectorStore<T: Decodable & Sendable>(
        vectorStore: VectorStore,
        query: String
    ) async throws(RailengineError) -> [T] {
        let documents = try await fetchSearchDocuments(vectorStore: vectorStore, query: query)
        return documents.compactMap { try? contentDecoder.decode($0.content) }
    }

    /// Searches a vector store and returns the full response envelope for each result.
    /// Each `SearchDocument` contains all API fields: EventId, Score, Content (as a raw string), etc.
    public func searchVectorStore(
        vectorStore: VectorStore,
        query: String
    ) async throws(RailengineError) -> [SearchDocument] {
        return try await fetchSearchDocuments(vectorStore: vectorStore, query: query)
    }

    // MARK: - Hot Storage
    /// Retrieves a storage document by EventId and decodes its `content` JSON string into `T`.
    /// Returns `nil` if the document is not found or `content` cannot be decoded into `T`.
    public func getStorageDocumentByEventId<T: Decodable & Sendable>(eventId: String) async throws(RailengineError) -> T? {
        guard let document = try await fetchStorageDocument(eventId: eventId) else { return nil }
        return try? contentDecoder.decode(document.content)
    }

    /// Retrieves a storage document by EventId and returns the full engine document envelope.
    /// Returns `nil` if the document is not found.
    public func getStorageDocumentByEventId(eventId: String) async throws(RailengineError) -> EngineDocument? {
        return try await fetchStorageDocument(eventId: eventId)
    }

    // MARK: - Hot Storage by CustomerKey

    /// Retrieves one page of storage documents for a CustomerKey and decodes each item's content into `T`.
    /// Documents whose `content` cannot be decoded into `T` are silently skipped.
    public func getStorageDocumentByCustomerKey<T: Decodable & Sendable>(
        customerKey: String,
        options: StorageQueryOptions? = nil
    ) async throws(RailengineError) -> StoragePage<T> {
        let response = try await fetchCustomerKeyPageResponse(customerKey: customerKey, options: options)
        let items: [T] = response.items.compactMap { try? contentDecoder.decode($0.content) }
        return StoragePage(items: items, totalPages: response.totalPages)
    }

    /// Retrieves one page of storage documents for a CustomerKey and returns the full engine document envelope.
    public func getStorageDocumentByCustomerKey(
        customerKey: String,
        options: StorageQueryOptions? = nil
    ) async throws(RailengineError) -> EngineDocumentPage {
        let response = try await fetchCustomerKeyPageResponse(customerKey: customerKey, options: options)
        return EngineDocumentPage(items: response.items.map { $0.asEngineDocument }, totalPages: response.totalPages)
    }

    // MARK: - Hot Storage by JSONPath

    /// Retrieves one page of storage documents matching a JSONPath query and decodes each item's content into `T`.
    /// Documents whose `content` cannot be decoded into `T` are silently skipped.
    public func getStorageDocumentsByJsonPath<T: Decodable>(
        jsonPathQuery: String,
        options: StorageQueryOptions? = nil
    ) async throws(RailengineError) -> StoragePage<T> {
        let response = try await fetchJsonPathPageResponse(jsonPathQuery: jsonPathQuery, options: options)
        let items: [T] = response.items.compactMap { try? contentDecoder.decode($0.content) }
        return StoragePage(items: items, totalPages: response.totalPages)
    }

    /// Retrieves one page of storage documents matching a JSONPath query and returns the full engine document envelope.
    public func getStorageDocumentsByJsonPath(
        jsonPathQuery: String,
        options: StorageQueryOptions? = nil
    ) async throws(RailengineError) -> EngineDocumentPage {
        let response = try await fetchJsonPathPageResponse(jsonPathQuery: jsonPathQuery, options: options)
        return EngineDocumentPage(items: response.items.map { $0.asEngineDocument }, totalPages: response.totalPages)
    }

    // MARK: - Indexing

    /// Searches the index and decodes each result's `content` into `T`.
    /// Items whose `content` cannot be decoded into `T` are silently skipped.
    public func searchIndex<T: Decodable & Sendable>(
        query: IndexQuery
    ) async throws(RailengineError) -> [T] {
        let updatedQuery = query.appendingBodySelect()
        let documents = try await fetchIndexDocuments(query: updatedQuery)
        return documents.compactMap {
            guard let body = $0.body else { return nil }
            return try? contentDecoder.decode(body)
        }
    }

    /// Searches the index and returns the full document envelope for each result.
    public func searchIndex(
        query: IndexQuery
    ) async throws(RailengineError) -> [IndexDocument] {
        return try await fetchIndexDocuments(query: query)
    }

    // MARK: - Deletion

    public func deleteEvent(eventId: String) async throws(RailengineError) {
        try await performDeleteEvent(eventId: eventId)
    }

    // MARK: - List Storage Documents
    /// Retrieves one page of storage documents and decodes each item's content into `T`.
    /// Documents whose `content` cannot be decoded into `T` are silently skipped.
    public func listStorageDocuments<T: Decodable>(
        options: StorageQueryOptions? = nil
    ) async throws(RailengineError) -> StoragePage<T> {
        let response = try await fetchStorageDocumentsPageResponse(options: options)
        let items: [T] = response.items.compactMap { try? contentDecoder.decode($0.content) }
        return StoragePage(items: items, totalPages: response.totalPages)
    }

    /// Retrieves one page of storage documents and returns the full engine document envelope.
    public func listStorageDocuments(
        options: StorageQueryOptions? = nil
    ) async throws(RailengineError) -> EngineDocumentPage {
        let response = try await fetchStorageDocumentsPageResponse(options: options)
        return EngineDocumentPage(items: response.items.map { $0.asEngineDocument }, totalPages: response.totalPages)
    }
}

private extension Railengine {

    func fetchJsonPathPageResponse(
        jsonPathQuery: String,
        options: StorageQueryOptions?
    ) async throws(RailengineError) -> StoragePagedResponse {
        let pageNumber = options?.pageNumber ?? 1
        let pageSize = options?.pageSize ?? 25
        guard let url = urlBuilder.storageJsonPathURL(jsonPathQuery, pageNumber: pageNumber, pageSize: pageSize) else {
            throw RailengineError.invalidUrl
        }
        do {
            return try await clientNetwork.get(url: url)
        } catch {
            throw RailengineError(error)
        }
    }

    func fetchStorageDocumentsPageResponse(
        options: StorageQueryOptions?
    ) async throws(RailengineError) -> StoragePagedResponse {
        let pageNumber = options?.pageNumber ?? 1
        let pageSize = options?.pageSize ?? 25
        guard let url = urlBuilder.storageListURL(pageNumber: pageNumber, pageSize: pageSize) else {
            throw RailengineError.invalidUrl
        }
        do {
            return try await clientNetwork.get(url: url)
        } catch {
            throw RailengineError(error)
        }
    }

    func fetchCustomerKeyPageResponse(
        customerKey: String,
        options: StorageQueryOptions?
    ) async throws(RailengineError) -> StoragePagedResponse {
        let pageNumber = options?.pageNumber ?? 1
        let pageSize = options?.pageSize ?? 25
        guard let url = urlBuilder.storageCustomerKeyURL(customerKey, pageNumber: pageNumber, pageSize: pageSize) else {
            throw RailengineError.invalidUrl
        }
        do {
            return try await clientNetwork.get(url: url)
        } catch {
            throw RailengineError(error)
        }
    }

    func fetchStorageDocument(eventId: String) async throws(RailengineError) -> EngineDocument? {
        guard let url = urlBuilder.storageEventIdURL(eventId) else {
            throw RailengineError.invalidEventId
        }
        do {
            return try await clientNetwork.get(url: url)
        } catch {
            throw RailengineError(error)
        }
    }

    func fetchIndexDocuments<Query: Encodable & Sendable>(
        query: Query
    ) async throws(RailengineError) -> [IndexDocument] {
        let body = IndexSearchRequest(engineId: engineId, query: query)
        do {
            let response: IndexSearchResponse = try await clientNetwork.post(url: urlBuilder.indexingSearchURL(), body: body)
            return response.value
        } catch {
            throw RailengineError(error)
        }
    }

    func fetchSearchDocuments(vectorStore: VectorStore, query: String) async throws(RailengineError) -> [SearchDocument] {
        let body = EmbeddingsSearchRequest(query: query, vectorStore: vectorStore.rawValue)
        do {
            return try await clientNetwork.post(url: urlBuilder.embeddingsSearchURL(), body: body)
        } catch {
            throw RailengineError(error)
        }
    }

    func performDeleteEvent(eventId: String) async throws(RailengineError) {
        let url = urlBuilder.deleteEventURL(eventId)
        do {
            try await clientNetwork.delete(url: url)
        } catch {
            throw RailengineError(error)
        }
    }
}
