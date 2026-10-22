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

    public static var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: identifier)
    }

    // Storage Keys
    public static let keyLastSMSEvaluation = "triage_last_sms_evaluation_ts"
    public static let keyLastSafariEvaluation = "triage_last_safari_evaluation_ts"
    public static let keySMSConfiguredByUser = "triage_sms_configured_by_user"
    public static let keySafariConfiguredByUser = "triage_safari_configured_by_user"

    // Heartbeat Recorders
    public static func recordSMSHeartbeat() {
        userDefaults?.set(Date().timeIntervalSince1970, forKey: keyLastSMSEvaluation)
        userDefaults?.set(true, forKey: keySMSConfiguredByUser)
    }

    public static func recordSafariHeartbeat() {
        userDefaults?.set(Date().timeIntervalSince1970, forKey: keyLastSafariEvaluation)
        userDefaults?.set(true, forKey: keySafariConfiguredByUser)
    }

    public static func clearSMSHeartbeat() {
        userDefaults?.removeObject(forKey: keyLastSMSEvaluation)
    }

    public static func clearSafariHeartbeat() {
        userDefaults?.removeObject(forKey: keyLastSafariEvaluation)
    }

    public static var lastSMSEvaluationDate: Date? {
        guard let ts = userDefaults?.double(forKey: keyLastSMSEvaluation), ts > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: ts)
    }

    public static var lastSafariEvaluationDate: Date? {
        guard let ts = userDefaults?.double(forKey: keyLastSafariEvaluation), ts > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: ts)
    }

    public static var isSMSConfiguredByUser: Bool {
        get { userDefaults?.bool(forKey: keySMSConfiguredByUser) ?? false }
        set { userDefaults?.set(newValue, forKey: keySMSConfiguredByUser) }
    }

    public static var isSafariConfiguredByUser: Bool {
        get { userDefaults?.bool(forKey: keySafariConfiguredByUser) ?? false }
        set { userDefaults?.set(newValue, forKey: keySafariConfiguredByUser) }
    }
}

