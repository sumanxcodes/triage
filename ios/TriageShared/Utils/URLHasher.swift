import CryptoKit
import Foundation

public enum URLHasher {
    private static let trackingParams: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "fbclid", "gclid", "msclkid", "ref"
    ]

    /// Extracts URLs from plain text using NSDataDetector.
    public static func extractURLs(from text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches.compactMap { $0.url }
    }

    /// Computes SHA-256 hexadecimal string for a given URL string.
    public static func sha256(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Strips tracking parameters, fragments, and standardizes lowercased scheme/host.
    public static func canonicalize(url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url.absoluteString.lowercased()
        }

        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        components.fragment = nil

        if let queryItems = components.queryItems {
            let filtered = queryItems
                .filter { !trackingParams.contains($0.name.lowercased()) }
                .sorted { $0.name < $1.name }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }

        return components.url?.absoluteString ?? url.absoluteString
    }

    private static let twoLevelTLDs: Set<String> = [
        "com.au", "net.au", "org.au", "gov.au", "edu.au",
        "co.uk", "org.uk", "me.uk", "ltd.uk",
        "co.nz", "net.nz", "org.nz", "govt.nz",
        "co.jp", "ne.jp", "com.br", "co.za"
    ]

    /// Extracts the registered root domain (handling two-level ccTLDs like .com.au or .co.uk).
    public static func extractRegisteredDomain(from hostname: String) -> String {
        let cleanHost = hostname.split(separator: ":").first.map(String.init)?.lowercased() ?? hostname.lowercased()
        let parts = cleanHost.split(separator: ".").map(String.init)
        if parts.count <= 2 {
            return cleanHost
        }

        let lastTwo = "\(parts[parts.count - 2]).\(parts[parts.count - 1])"
        if twoLevelTLDs.contains(lastTwo) && parts.count >= 3 {
            return parts.suffix(3).joined(separator: ".")
        }

        return parts.suffix(2).joined(separator: ".")
    }

    /// Generates multi-level candidate hashes: canonical URL hash and root host/domain hash.
    public static func candidateHashes(for url: URL) -> [String] {
        var hashes: [String] = []

        // 1. Canonical URL hash
        let canonical = canonicalize(url: url)
        hashes.append(sha256(canonical))

        // 2. Raw URL hash
        let raw = url.absoluteString
        if raw != canonical {
            hashes.append(sha256(raw))
        }

        // 3. Hostname hash & registered root domain hash
        if let host = url.host?.lowercased() {
            hashes.append(sha256(host))

            let rootDomain = extractRegisteredDomain(from: host)
            if rootDomain != host {
                hashes.append(sha256(rootDomain))
            }
        }

        return hashes
    }
}
