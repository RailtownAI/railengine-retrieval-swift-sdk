/// A single page of results from a paginated Hot Storage query.
public struct PaginatedResponse<T> {
    /// The decoded items in this page.
    public let items: [T]
    /// The page number this response represents.
    public let pageNumber: Int
    /// Total number of pages available.
    public let totalPages: Int
}
