import Foundation

public struct AppGroupState: Codable {
    public var lastSMSEvaluation: Double?
    public var lastSafariEvaluation: Double?
    public var isSMSConfigured: Bool
    public var isSafariConfigured: Bool

    public init(
        lastSMSEvaluation: Double? = nil,
        lastSafariEvaluation: Double? = nil,
        isSMSConfigured: Bool = false,
        isSafariConfigured: Bool = false
    ) {
        self.lastSMSEvaluation = lastSMSEvaluation
        self.lastSafariEvaluation = lastSafariEvaluation
        self.isSMSConfigured = isSMSConfigured
        self.isSafariConfigured = isSafariConfigured
    }
}

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

    private static var stateFileURL: URL {
        return containerURL.appendingPathComponent("extension_state.json")
    }

    // Direct filesystem state access (avoids CFPreferences / cfprefsd daemon issues)
    public static func loadState() -> AppGroupState {
        guard let data = try? Data(contentsOf: stateFileURL),
              let state = try? JSONDecoder().decode(AppGroupState.self, from: data) else {
            return AppGroupState()
        }
        return state
    }

    public static func updateState(_ modify: (inout AppGroupState) -> Void) {
        var state = loadState()
        modify(&state)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: stateFileURL, options: .atomic)
        }
    }

    // Heartbeat Recorders
    public static func recordSMSHeartbeat() {
        updateState { state in
            state.lastSMSEvaluation = Date().timeIntervalSince1970
            state.isSMSConfigured = true
        }
    }

    public static func recordSafariHeartbeat() {
        updateState { state in
            state.lastSafariEvaluation = Date().timeIntervalSince1970
            state.isSafariConfigured = true
        }
    }

    public static func clearSMSHeartbeat() {
        updateState { state in
            state.lastSMSEvaluation = nil
        }
    }

    public static func clearSafariHeartbeat() {
        updateState { state in
            state.lastSafariEvaluation = nil
        }
    }

    public static var lastSMSEvaluationDate: Date? {
        guard let ts = loadState().lastSMSEvaluation, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    public static var lastSafariEvaluationDate: Date? {
        guard let ts = loadState().lastSafariEvaluation, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    public static var isSMSConfiguredByUser: Bool {
        get { loadState().isSMSConfigured }
        set {
            updateState { state in
                state.isSMSConfigured = newValue
            }
        }
    }

    public static var isSafariConfiguredByUser: Bool {
        get { loadState().isSafariConfigured }
        set {
            updateState { state in
                state.isSafariConfigured = newValue
            }
        }
    }
}
