public struct IndexDocument: Decodable, Sendable {
    
    public struct Property: Decodable, Sendable {
        public let key: String
        public let value: String
    }
    
    public let documentScore: String?
    public let eventId: String?
    public let engineId: String?
    public let projectId: String?
    public let managedProjectId: String?
    public let customerKey: String?
    public let body: String?
    public let key: String?
    public let searchableContent1: String?
    public let searchableContent2: String?
    public let searchableContent3: String?
    public let properties: [Property]?
    public let facetableField1: String?
    public let facetableField2: String?
    public let facetableField3: String?
    public let facetableField4: String?
    public let facetableField5: String?
    public let facetableField6: String?
    public let facetableField7: String?
    public let facetableField8: String?
    public let facetableField9: String?
    public let facetableField10: String?
}
