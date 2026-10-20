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

        let hash = URLHasher.sha256(urlString)
        let isBlocked = ThreatDatabase.shared.isThreat(urlHash: hash)

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
