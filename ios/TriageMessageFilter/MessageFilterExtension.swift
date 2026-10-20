import Foundation
import IdentityLookup

final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()

        // 1. Check if message body exists
        guard let messageBody = queryRequest.messageBody, !messageBody.isEmpty else {
            response.action = .none
            completion(response)
            return
        }

        // 2. Extract URLs from SMS
        let urls = URLHasher.extractURLs(from: messageBody)

        // 3. Fast O(1) Local SQLite lookup using GRDB.swift
        for url in urls {
            let hash = URLHasher.sha256(url.absoluteString)
            if ThreatDatabase.shared.isThreat(urlHash: hash) {
                response.action = .junk
                completion(response)
                return
            }
        }

        // 4. If inconclusive and message contains suspicious links, defer to network
        if !urls.isEmpty {
            context.deferQueryRequestToNetwork { networkResponse, error in
                if let networkResponse = networkResponse {
                    response.action = networkResponse.action
                } else {
                    response.action = .none
                }
                completion(response)
            }
        } else {
            response.action = .none
            completion(response)
        }
    }
}
