import Foundation
import SafariServices

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem,
              let userInfo = item.userInfo as? [String: Any],
              let message = userInfo[SFExtensionMessageKey] as? [String: Any],
              let urlString = message["url"] as? String else {
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        var isBlocked = false
        if let url = URL(string: urlString) {
            let candidateHashes = URLHasher.candidateHashes(for: url)
            isBlocked = ThreatDatabase.shared.isThreat(candidateHashes: candidateHashes)
        } else {
            let hash = URLHasher.sha256(urlString)
            isBlocked = ThreatDatabase.shared.isThreat(urlHash: hash)
        }

        NSLog("[Triage Safari] Evaluating URL: %@ -> Result: %@", urlString, isBlocked ? "BLOCK" : "ALLOW")

        if isBlocked {
            var category = "phishing"
            var targetBrand: String?
            if let url = URL(string: urlString) {
                let candidateHashes = URLHasher.candidateHashes(for: url)
                if let match = ThreatDatabase.shared.findThreat(candidateHashes: candidateHashes) {
                    category = match.category
                    targetBrand = match.targetBrand
                }
            }
            ThreatDatabase.shared.recordEvent(
                source: "safari",
                target: urlString,
                category: category,
                targetBrand: targetBrand,
                actionTaken: "blocked"
            )
        }

        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "url": urlString,
                "action": isBlocked ? "block" : "allow"
            ]
        ]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
