import Testing
import Foundation
@testable import Railengine

@Suite("IndexQuery")
struct IndexQueryTests {

    // MARK: searchFields mapping

    @Test(
        "searchFields maps SearchField values to comma-separated string",
        arguments: zip(
            [
                [.SearchableContent1] as [IndexQuery.SearchField]?,
                [.SearchableContent1, .SearchableContent2],
                [.SearchableContent1, .SearchableContent2, .SearchableContent3],
                nil,
            ],
            [
                "SearchableContent1",
                "SearchableContent1, SearchableContent2",
                "SearchableContent1, SearchableContent2, SearchableContent3",
                nil,
            ] as [String?]
        )
    )
    func searchFieldsMapping(fields: [IndexQuery.SearchField]?, expected: String?) {
        let query = IndexQuery(search: "*", searchFields: fields)
        #expect(query.searchFields == expected)
    }
}
