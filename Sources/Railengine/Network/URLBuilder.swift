import Foundation

protocol URLBuilding: Sendable {

    func embeddingsSearchURL() -> URL
    func indexingSearchURL() -> URL
    func storageEventIdURL(_ eventId: String) -> URL?
    func storageCustomerKeyURL(_ customerKey: String, pageNumber: Int, pageSize: Int) -> URL?
    func storageJsonPathURL(_ query: String, pageNumber: Int, pageSize: Int) -> URL?
    func storageListURL(pageNumber: Int, pageSize: Int) -> URL?
    func deleteEventURL(_ eventId: String) -> URL
}

struct URLBuilder: URLBuilding {

    let baseURL: URL
    let engineId: String

    private var storageBase: URL {
        baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("Engine")
            .appendingPathComponent(engineId)
            .appendingPathComponent("Storage")
    }

    // MARK: Embeddings

    func embeddingsSearchURL() -> URL {
        baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("Engine")
            .appendingPathComponent(engineId)
            .appendingPathComponent("Embeddings")
            .appendingPathComponent("Search")
    }

    // MARK: Indexing

    func indexingSearchURL() -> URL {
        baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("Engine")
            .appendingPathComponent("Indexing")
            .appendingPathComponent("Search")
    }

    // MARK: Storage

    func storageEventIdURL(_ eventId: String) -> URL? {
        var components = URLComponents(url: storageBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "EventId", value: eventId)]
        return components?.url
    }

    func storageCustomerKeyURL(_ customerKey: String, pageNumber: Int, pageSize: Int) -> URL? {
        var components = URLComponents(url: storageBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "CustomerKey", value: customerKey),
            URLQueryItem(name: "PageNumber", value: "\(pageNumber)"),
            URLQueryItem(name: "PageSize", value: "\(pageSize)"),
        ]
        return components?.url
    }

    func storageJsonPathURL(_ query: String, pageNumber: Int, pageSize: Int) -> URL? {
        var components = URLComponents(url: storageBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "JsonPathQuery", value: query),
            URLQueryItem(name: "PageNumber", value: "\(pageNumber)"),
            URLQueryItem(name: "PageSize", value: "\(pageSize)"),
        ]
        return components?.url
    }

    func storageListURL(pageNumber: Int, pageSize: Int) -> URL? {
        var components = URLComponents(url: storageBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "PageNumber", value: "\(pageNumber)"),
            URLQueryItem(name: "PageSize", value: "\(pageSize)"),
        ]
        return components?.url
    }

    // MARK: Deletion

    func deleteEventURL(_ eventId: String) -> URL {
        baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("Engine")
            .appendingPathComponent(engineId)
            .appendingPathComponent("Event")
            .appendingPathComponent(eventId)
    }
}
