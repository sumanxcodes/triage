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

    /// Insert or update threat records during sync.
    public func save(threats: [ThreatRecord]) throws {
        try dbQueue.write { db in
            for threat in threats {
                try threat.save(db)
            }
        }
    }
}
