import Foundation
import GRDB

/// On-device audit log record for threats intercepted in Safari or SMS
public struct ThreatEventRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    public static let databaseTableName = "threat_events"

    public var id: UUID
    public var source: String // "safari" or "sms"
    public var target: String // Malicious URL or domain
    public var sender: String? // SMS sender (e.g. "+61 412 345 678")
    public var category: String // "phishing", "credential_harvesting", etc.
    public var targetBrand: String? // "Australia Post", "Apple", etc.
    public var actionTaken: String // "blocked", "filtered_to_junk"
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        source: String,
        target: String,
        sender: String? = nil,
        category: String = "phishing",
        targetBrand: String? = nil,
        actionTaken: String = "blocked",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.target = target
        self.sender = sender
        self.category = category
        self.targetBrand = targetBrand
        self.actionTaken = actionTaken
        self.timestamp = timestamp
    }
}
