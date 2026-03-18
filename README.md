# Railengine - Swift SDK

A Swift Package for retrieving and searching data from Railengine.
 
**Platforms:** iOS 17+ | macOS 14+ | Mac Catalyst 16+

## Installation

### Swift Package Manager (Xcode)

1. In Xcode, go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/RailtownAI/railengine-retrieval-swift-sdk
   ```
3. Select your desired version rule (e.g. **Up to Next Major Version**)
4. Click **Add Package**
5. In the target selection dialog, make sure **Railengine** is added to your app target

### Swift Package Manager (Package.swift)

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RailtownAI/railengine-retrieval-swift-sdk", from: "1.0.0")
]
```

Then add `Railengine` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["Railengine"]
)
```

## Authentication

The SDK authenticates using a **Personal Access Token (PAT)**.

Copy the token and store it securely in your app (e.g. in a configuration file or secrets manager):

```
[INSERT PAT TOKEN HERE]
```

> **Note:** Consider using Xcode build configurations or `.xcconfig` files to avoid hardcoding tokens in source code.

## Code Example

Here's a simple example of how to search a vector store using the Swift SDK:

```swift
import Railengine

// 1. Initialize the client with your PAT and engine ID
let client = try Railengine(pat: "[INSERT PAT TOKEN HERE]", engineId: "[INSERT ENGINE ID HERE]")

// 2. Search the vector store
let results: [SearchDocument] = try await client.searchVectorStore(
    vectorStore: .VectorStore1,
    query: "your search query"
)

for result in results {
    print(result.content)
}
```

### SwiftUI Example

```swift
import SwiftUI
import Railengine

struct ContentView: View {
    let client: Railengine

    init() {
        do {
            self.client = try Railengine(
                pat: "[INSERT PAT TOKEN HERE]",
                engineId: "[INSERT ENGINE ID HERE]"
            )
        } catch {
            fatalError("Invalid configuration: \(error)")
        }
    }

    var body: some View {
        Button("Search") {
            Task {
                let results: [SearchDocument] = try await client.searchVectorStore(
                    vectorStore: .VectorStore1,
                    query: "your search query"
                )
                print("Found \(results.count) results")
            }
        }
    }
}
```

## API Methods

### Embeddings API

#### `searchVectorStore`

Search a vector store using semantic similarity. Results are ordered by relevance score.

**Raw overload** — returns the full response envelope when no type is specified:

```swift
let results: [SearchDocument] = try await client.searchVectorStore(
    vectorStore: .VectorStore1,
    query: "search query"
)

for result in results {
    print(result.eventId)   // Unique identifier
    print(result.score)     // Similarity score
    print(result.content)   // Raw JSON string of the stored payload
}
```

**Typed overload** — automatically decodes the `Content` field into your own type. Items whose content doesn't match the schema are silently skipped:

```swift
struct FoodDiaryItem: Decodable, Sendable {
    let foodName: String
    let calories: Int
}

let items: [FoodDiaryItem] = try await client.searchVectorStore(
    vectorStore: .VectorStore1,
    query: "apple"
)

for item in items {
    print(item.foodName, item.calories)
}
```


### Hot Storage API

Hot Storage methods retrieve documents from the engine's document store. All paged methods accept an optional `StorageQueryOptions` to control pagination (`pageNumber` defaults to 1, `pageSize` defaults to 25 and is capped at 100).

Each method has two overloads:
- **Raw overload** — returns the full `EngineDocument` envelope, useful for inspecting metadata.
- **Typed overload** — decodes the `content` field directly into your own type. Documents whose content doesn't match the schema are silently skipped.

---

#### `getStorageDocumentByEventId`

Fetch a single document by its EventId. Returns `nil` if not found.

**Raw overload:**

```swift
let doc: EngineDocument? = try await client.getStorageDocumentByEventId(eventId: "abc-123")

print(doc?.eventId)      // Unique event identifier
print(doc?.customerKey)  // Associated customer key
print(doc?.content)      // Raw JSON string of the stored payload
```

**Typed overload** — decodes `content` into `T`, returns `nil` on schema mismatch or not found:

```swift
struct FoodDiaryItem: Decodable, Sendable {
    let foodName: String
    let calories: Int
}

let item: FoodDiaryItem? = try await client.getStorageDocumentByEventId(eventId: "abc-123")
print(item?.foodName)
```

---

#### `getStorageDocumentByCustomerKey`

Fetch a paginated page of documents associated with a customer key.

**Raw overload:**

```swift
let page: EngineDocumentPage = try await client.getStorageDocumentByCustomerKey(
    customerKey: "user-42",
    options: StorageQueryOptions(pageNumber: 1, pageSize: 25)
)

print(page.totalPages)
for doc in page.items {
    print(doc.eventId, doc.content)
}
```

**Typed overload** — items that can't be decoded into `T` are silently skipped:

```swift
let page: StoragePage<FoodDiaryItem> = try await client.getStorageDocumentByCustomerKey(
    customerKey: "user-42"
)

for item in page.items {
    print(item.foodName, item.calories)
}
```

---

#### `getStorageDocumentsByJsonPath`

Fetch a paginated page of documents matching a JSONPath filter. Query format: `"$.fieldName:value"`.

**Raw overload:**

```swift
let page: EngineDocumentPage = try await client.getStorageDocumentsByJsonPath(
    jsonPathQuery: "$.user_id:user_42",
    options: StorageQueryOptions(pageNumber: 1, pageSize: 25)
)

print(page.totalPages)
for doc in page.items {
    print(doc.eventId, doc.content)
}
```

**Typed overload** — items that can't be decoded into `T` are silently skipped:

```swift
let page: StoragePage<FoodDiaryItem> = try await client.getStorageDocumentsByJsonPath(
    jsonPathQuery: "$.calories:500"
)

for item in page.items {
    print(item.foodName)
}
```

---

#### `listStorageDocuments`

Fetch a paginated page of all documents with no filter.

**Raw overload:**

```swift
let page: EngineDocumentPage = try await client.listStorageDocuments(
    options: StorageQueryOptions(pageNumber: 1, pageSize: 25)
)

print(page.totalPages)
for doc in page.items {
    print(doc.eventId, doc.content)
}
```

**Typed overload** — items that can't be decoded into `T` are silently skipped:

```swift
let page: StoragePage<FoodDiaryItem> = try await client.listStorageDocuments()

for item in page.items {
    print(item.foodName, item.calories)
}
```

---

### Indexing API

The Indexing API runs full-text and faceted searches against the engine's index. Each method has two overloads:
- **Typed overload** — decodes matching documents into your own type. Documents whose body doesn't match the schema are silently skipped.
- **Raw overload** — returns the full `IndexDocument` envelope, useful for inspecting all fields.

---

#### `searchIndex`

Search the index using a structured `IndexQuery`.

**Typed overload:**

```swift
struct Article: Decodable, Sendable {
    let title: String
    let body: String
}

let query = IndexQuery(
    search: "swift concurrency",
    queryType: .simple,
    searchMode: .any,
    top: 10
)

let articles: [Article] = try await client.searchIndex(query: query)

for article in articles {
    print(article.title, article.body)
}
```

**Raw overload** — returns `[IndexDocument]`:

```swift
let query = IndexQuery(search: "*")  // match all documents

let documents: [IndexDocument] = try await client.searchIndex(query: query)

for doc in documents {
    print(doc.eventId)   // Unique event identifier
    print(doc.score)     // Relevance score
    print(doc.body)      // Raw JSON string of the stored payload
}
```

**`IndexQuery` parameters:**

| Parameter | Type | Description |
|---|---|---|
| `search` | `String` | Full-text expression. Use `"*"` to match all documents. |
| `queryType` | `IndexQueryType?` | `.simple` (default) or `.full` (Lucene syntax) |
| `searchMode` | `IndexSearchMode?` | `.any` (default) or `.all` |
| `filter` | `String?` | OData filter expression for exact field matching |
| `top` | `Int?` | Maximum number of results to return |
| `skip` | `Int?` | Number of results to skip (for pagination) |
| `searchFields` | `[SearchField]?` | Restrict full-text search to specific fields |
| `facets` | `[Facet]?` | Return counts grouped by the named facet category |

---

### Deletion API

#### `deleteEvent`

Delete a single event by its EventId. Throws on failure; returns `Void` on success.

```swift
try await client.deleteEvent(eventId: "abc-123")
```

---

## Error Handling

All public methods throw `RailengineError` on network or HTTP failures. Decoding failures are handled gracefully: typed overloads return `nil` for single-document lookups, or silently skip non-matching items in paged and index results.

| Error | Reason |
|---|---|
| `invalidUrl` | The `apiUrl` provided is malformed |
| `invalidEngineId` | The engineId is empty or invalid |
| `invalidEventId` | The eventId is empty or malformed |
| `invalidResponse` | The server response was not a valid HTTP response |
| `missingPAT` | The PAT is empty |
| `httpError(statusCode:response:)` | Server returned a non-2xx response |
| `requestFailed(description:)` | Network-level failure |
| `encodingFailed(description:)` | Request body could not be encoded |
| `decodingFailed(description:)` | Response body could not be decoded |

```swift
do {
    let client = try Railengine(
        pat: "your-pat",
        engineId: "your-engine-id",
        apiUrl: "https://custom.railtown.ai"  // optional
    )
} catch RailengineError.invalidUrl {
    print("The API URL is invalid.")
}

do {
    let doc: EngineDocument? = try await client.getStorageDocumentByEventId(eventId: "abc-123")
} catch let error as RailengineError {
    print(error.debugDescription)
}
```

## License

See LICENSE file for details.
