/// Controls which query syntax is used for the `search` field.
public enum IndexQueryType: String, Encodable, Sendable {
    /// Default simple syntax. Supports AND, OR, NOT, and "exact phrases".
    case simple
    /// Full Lucene syntax. Enables wildcards, fuzzy search, and proximity search.
    case full
}

/// Controls whether any or all search terms must match.
public enum IndexSearchMode: String, Encodable, Sendable {
    /// At least one term must match (default).
    case any
    /// All terms must match.
    case all
}

/// A query for the Indexing search API.
public struct IndexQuery: Encodable, Sendable {

    public enum Facet: String, Encodable, Sendable, CaseIterable {
        case FacetableField1, FacetableField2, FacetableField3, FacetableField4, FacetableField5, FacetableField6, FacetableField7, FacetableField8, FacetableField9, FacetableField10
    }
    
    public enum SearchField: String, Encodable, Sendable, CaseIterable {
        case SearchableContent1, SearchableContent2, SearchableContent3
    }
    
    /// Full-text search expression. Supports AND, OR, NOT, "exact phrases".
    /// Use `"*"` to match all documents.
    public let search: String

    /// Query syntax. Defaults to `.simple`; use `.full` for Lucene wildcards and fuzzy search.
    public let queryType: IndexQueryType?

    /// Term-matching mode. Defaults to `.any`; use `.all` to require every term.
    public let searchMode: IndexSearchMode?

    /// When `true`, the response includes the total count of matching documents.
    public let count: Bool?

    /// OData filter expression for exact field matching.
    /// Example: `"Properties/any(p: p/Key eq '$.timestamp' and p/Value ge '2026-03-03T00:00:00Z')"`
    public let filter: String?

    /// Number of results to skip (for pagination).
    public let skip: Int?

    /// Maximum number of results to return.
    public let top: Int?

    /// Comma-separated list of fields to include in each result. String needs to be PascalCase.
    public let select: String?

    /// Restricts full-text search to a specific searchable content field.
    public let searchFields: String?

    /// Returns counts grouped by the named facet category.
    public let facets: [Facet]?

    public init(
        search: String,
        queryType: IndexQueryType? = nil,
        searchMode: IndexSearchMode? = nil,
        count: Bool? = nil,
        filter: String? = nil,
        skip: Int? = nil,
        top: Int? = nil,
        select: String? = nil,
        searchFields: [SearchField]? = nil,
        facets: [Facet]? = nil
    ) {
        self.search = search
        self.queryType = queryType
        self.searchMode = searchMode
        self.count = count
        self.filter = filter
        self.skip = skip
        self.top = top
        self.select = select
        self.searchFields = searchFields?.map({ $0.rawValue }).joined(separator: ", ")
        self.facets = facets
    }
    
    init(
        with search: String,
        queryType: IndexQueryType? = nil,
        searchMode: IndexSearchMode? = nil,
        count: Bool? = nil,
        filter: String? = nil,
        skip: Int? = nil,
        top: Int? = nil,
        select: String? = nil,
        searchFieldsString: String? = nil,
        facets: [Facet]? = nil
    ) {
        self.search = search
        self.queryType = queryType
        self.searchMode = searchMode
        self.count = count
        self.filter = filter
        self.skip = skip
        self.top = top
        self.select = select
        self.searchFields = searchFieldsString
        self.facets = facets
    }
    
    func appendingBodySelect() -> IndexQuery {
        if let select, !select.uppercased().contains("BODY") {
            IndexQuery(
                with: search,
                queryType: queryType,
                searchMode: searchMode,
                count: count,
                filter: filter,
                skip: skip,
                top: top,
                select: select + ", Body",
                searchFieldsString: searchFields,
                facets: facets
            )
        } else {
            self
        }
    }
}
