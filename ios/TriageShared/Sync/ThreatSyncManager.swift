import BackgroundTasks
import Foundation

public struct ThreatDeltaPayload: Codable {
    public struct HashItem: Codable {
        public let hash: String
        public let domain_hash: String?
        public let category: String
        public let target_brand: String?
        public let created_at: Date
    }

    public let timestamp: Date
    public let added_hashes: [HashItem]
    public let removed_hashes: [String]
}

public final class ThreatSyncManager {
    public static let shared = ThreatSyncManager()
    public static let backgroundTaskIdentifier = "com.sumanxcodes.triage.threatsync"

    private let defaults = UserDefaults(suiteName: AppGroup.identifier)
    private let lastSyncKey = "triage_last_threat_sync_date"

    public var lastSyncDate: Date? {
        get { defaults?.object(forKey: lastSyncKey) as? Date }
        set { defaults?.set(newValue, forKey: lastSyncKey) }
    }

    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Performs incremental delta sync from backend API and updates local GRDB SQLite.
    public func sync(
        baseURL: URL = URL(string: "https://api.triage.security")!,
        session: URLSession = .shared
    ) async throws -> (added: Int, removed: Int) {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/api/v1/threats/delta"),
            resolvingAgainstBaseURL: true
        )

        if let lastSync = lastSyncDate {
            components?.queryItems = [
                URLQueryItem(name: "since", value: iso8601Formatter.string(from: lastSync))
            ]
        }

        guard let requestURL = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let delta = try decoder.decode(ThreatDeltaPayload.self, from: data)

        // 1. Insert/update newly added threats
        let records = delta.added_hashes.map { item in
            ThreatRecord(
                urlHash: item.hash,
                category: item.category,
                targetBrand: item.target_brand,
                createdAt: item.created_at
            )
        }
        if !records.isEmpty {
            try ThreatDatabase.shared.save(threats: records)
        }

        // 2. Remove revoked threats
        if !delta.removed_hashes.isEmpty {
            try ThreatDatabase.shared.delete(urlHashes: delta.removed_hashes)
        }

        // 3. Update sync timestamp in App Group UserDefaults
        lastSyncDate = delta.timestamp

        return (added: records.count, removed: delta.removed_hashes.count)
    }

    /// Schedules the next background refresh task via iOS BGTaskScheduler.
    public func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        // Request sync check every 6-12 hours
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule threat sync background task: \(error)")
        }
    }
}
