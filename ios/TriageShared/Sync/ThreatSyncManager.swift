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
        baseURL: URL = URL(string: "https://triage-api-oeyj.onrender.com")!,
        forceFullBootstrap: Bool = false,
        session: URLSession = .shared
    ) async throws -> (added: Int, removed: Int) {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/api/v1/threats/delta"),
            resolvingAgainstBaseURL: true
        )

        // Only query incremental delta if we already have a real database populated (> 9 items)
        let isInitialSeed = ThreatDatabase.shared.count() <= 9
        if let lastSync = lastSyncDate, !forceFullBootstrap, !isInitialSeed {
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

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Fallback for development/offline mode when live remote backend is not yet deployed
            return try seedDemoThreats()
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return try seedDemoThreats()
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

    /// Seeds initial verified threat hashes when testing offline or before remote server is reachable.
    public func seedDemoThreats() throws -> (added: Int, removed: Int) {
        let sampleThreats: [ThreatRecord] = [
            ThreatRecord(
                urlHash: "4b5d27d501d2a1b94bbfb16ce036ca6d2b9921601737be708f51a8775f0a6729",
                category: "phishing",
                targetBrand: "Australia Post",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "495447a16149495b23d91cf30b65f3a07ce11e4bfbe15b8109bfcf9ef0528e12",
                category: "credential_harvesting",
                targetBrand: "Commonwealth Bank",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "3eb33c2a11c817293a525d6bfe38a536968038ae11ec5a676a6e556e9c1dbfa2",
                category: "homoglyph_phishing",
                targetBrand: "Apple",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "0915668ef8f80470e9a4448202d609de99a4e320f04ca48eb038b341f2382cf8",
                category: "credential_harvesting",
                targetBrand: "Apple",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "80b58df99eba2a737040b73475199ef85441a98cdf77b22081057d11df28d621",
                category: "phishing_test",
                targetBrand: "Example Test",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "a379a6f6eeafb9a55e378c118034e2751e682fab9f2d30ab13d2125586ce1947",
                category: "phishing_test",
                targetBrand: "example.com (Domain Test)",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "100680ad546ce6a577f42f52df33b4cfdca756859e664b8d7de329b150d09ce9",
                category: "phishing_test",
                targetBrand: "https://example.com (URL Test)",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "0f115db062b7c0dd030b16878c99dea5c354b49dc37b38eb8846179c7783e9d7",
                category: "phishing_test",
                targetBrand: "https://example.com/ (URL Test)",
                createdAt: Date()
            ),
            ThreatRecord(
                urlHash: "5a2474b3a617c332f113a5ea8ca1be85fe299636dce3b0217e400c6c97136359",
                category: "phishing_test",
                targetBrand: "HttpBin Test",
                createdAt: Date()
            )
        ]

        try ThreatDatabase.shared.save(threats: sampleThreats)
        lastSyncDate = Date()
        return (added: sampleThreats.count, removed: 0)
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
