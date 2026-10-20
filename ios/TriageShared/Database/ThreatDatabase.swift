import Foundation
import GRDB

public final class ThreatDatabase {
    public static let shared = ThreatDatabase()

    private let dbQueue: DatabaseQueue

    public init(databaseURL: URL = AppGroup.databaseURL) {
        var config = Configuration()
        config.qos = .userInitiated
        // Optimize for fast concurrent reads and low memory
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
        }

        do {
            self.dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
            try migrator.migrate(self.dbQueue)
        } catch {
            fatalError("Could not initialize ThreatDatabase at \(databaseURL.path): \(error)")
        }
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_threats_table") { db in
            try db.create(table: ThreatRecord.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("urlHash", .text).notNull().unique(onConflict: .replace)
                t.column("category", .text).notNull().defaults(to: "phishing")
                t.column("targetBrand", .text)
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(
                index: "idx_threats_urlHash",
                on: ThreatRecord.databaseTableName,
                columns: ["urlHash"],
                ifNotExists: true
            )
        }

        migrator.registerMigration("v2_create_threat_events_table") { db in
            try db.create(table: ThreatEventRecord.databaseTableName, ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("source", .text).notNull()
                t.column("target", .text).notNull()
                t.column("sender", .text)
                t.column("category", .text).notNull().defaults(to: "phishing")
                t.column("targetBrand", .text)
                t.column("actionTaken", .text).notNull().defaults(to: "blocked")
                t.column("timestamp", .datetime).notNull()
            }
            try db.create(
                index: "idx_threat_events_timestamp",
                on: ThreatEventRecord.databaseTableName,
                columns: ["timestamp"],
                ifNotExists: true
            )
        }

        return migrator
    }

    /// Fast O(1) indexed threat hash check. Ideal for IdentityLookup extension constraints.
    public func isThreat(urlHash: String) -> Bool {
        do {
            return try dbQueue.read { db in
                try ThreatRecord
                    .filter(Column("urlHash") == urlHash)
                    .fetchCount(db) > 0
            }
        } catch {
            return false
        }
    }

    /// Fast O(1) multi-hash check across candidate keys (exact URL, domain, hostname).
    public func isThreat(candidateHashes: [String]) -> Bool {
        guard !candidateHashes.isEmpty else { return false }
        do {
            return try dbQueue.read { db in
                try ThreatRecord
                    .filter(candidateHashes.contains(Column("urlHash")))
                    .fetchCount(db) > 0
            }
        } catch {
            return false
        }
    }

    /// Insert or update threat records during sync.
    public func save(threats: [ThreatRecord]) throws {
        try dbQueue.write { db in
            for threat in threats {
                try threat.save(db)
            }
        }
    }

    /// Delete threat records by urlHash when revoked by backend.
    public func delete(urlHashes: [String]) throws {
        guard !urlHashes.isEmpty else { return }
        try dbQueue.write { db in
            try ThreatRecord
                .filter(urlHashes.contains(Column("urlHash")))
                .deleteAll(db)
        }
    }

    /// Total count of active threats stored in local SQLite cache.
    public func count() -> Int {
        do {
            return try dbQueue.read { db in
                try ThreatRecord.fetchCount(db)
            }
        } catch {
            return 0
        }
    }

    /// Finds matching threat record for enriched metadata (brand, category).
    public func findThreat(candidateHashes: [String]) -> ThreatRecord? {
        guard !candidateHashes.isEmpty else { return nil }
        do {
            return try dbQueue.read { db in
                try ThreatRecord
                    .filter(candidateHashes.contains(Column("urlHash")))
                    .fetchOne(db)
            }
        } catch {
            return nil
        }
    }

    // MARK: - On-Device Threat History & Event Logging

    /// Records an intercepted threat event into the local on-device audit log.
    @discardableResult
    public func recordEvent(
        source: String,
        target: String,
        sender: String? = nil,
        category: String = "phishing",
        targetBrand: String? = nil,
        actionTaken: String = "blocked"
    ) -> ThreatEventRecord? {
        let event = ThreatEventRecord(
            source: source,
            target: target,
            sender: sender,
            category: category,
            targetBrand: targetBrand,
            actionTaken: actionTaken,
            timestamp: Date()
        )
        do {
            try dbQueue.write { db in
                try event.save(db)
                // Auto-prune older events beyond 1000 records to keep DB compact
                try db.execute(sql: """
                    DELETE FROM \(ThreatEventRecord.databaseTableName)
                    WHERE id NOT IN (
                        SELECT id FROM \(ThreatEventRecord.databaseTableName)
                        ORDER BY timestamp DESC
                        LIMIT 1000
                    )
                """)
            }
            return event
        } catch {
            print("[ThreatDatabase] Failed to record threat event: \(error)")
            return nil
        }
    }

    /// Fetches chronological threat events for the history feed.
    public func fetchRecentEvents(limit: Int = 100) -> [ThreatEventRecord] {
        do {
            return try dbQueue.read { db in
                try ThreatEventRecord
                    .order(Column("timestamp").desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            print("[ThreatDatabase] Failed to fetch threat events: \(error)")
            return []
        }
    }

    /// Deletes a single event from the local history log.
    public func deleteEvent(id: UUID) {
        do {
            try dbQueue.write { db in
                _ = try ThreatEventRecord.deleteOne(db, id: id)
            }
        } catch {
            print("[ThreatDatabase] Failed to delete threat event: \(error)")
        }
    }

    /// Clears all local threat history events.
    public func clearAllEvents() {
        do {
            try dbQueue.write { db in
                try ThreatEventRecord.deleteAll(db)
            }
        } catch {
            print("[ThreatDatabase] Failed to clear threat events: \(error)")
        }
    }

    /// Returns the total number of intercepted threat events.
    public func eventsCount() -> Int {
        do {
            return try dbQueue.read { db in
                try ThreatEventRecord.fetchCount(db)
            }
        } catch {
            return 0
        }
    }
}
