import Foundation

public enum AppGroup {
    public static let identifier = "group.com.sumanxcodes.triage"

    public static var containerURL: URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            fatalError("Failed to access App Group container: \(identifier). Ensure entitlements are set up.")
        }
        return url
    }

    public static var databaseURL: URL {
        return containerURL.appendingPathComponent("threats.sqlite")
    }
}
