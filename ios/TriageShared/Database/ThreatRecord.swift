import Foundation
import GRDB

public struct ThreatRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "threats"

    public var id: Int64?
    public var urlHash: String
    public var category: String
    public var targetBrand: String?
    public var createdAt: Date

    public init(
        id: Int64? = nil,
        urlHash: String,
        category: String = "phishing",
        targetBrand: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.urlHash = urlHash
        self.category = category
        self.targetBrand = targetBrand
        self.createdAt = createdAt
    }
}
