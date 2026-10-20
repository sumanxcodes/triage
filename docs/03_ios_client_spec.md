# iOS Client Implementation Guide

## Target 1: Main Application (SwiftUI)
*   **Purpose:** User onboarding, UI, subscription management (StoreKit 2), and background syncing.
*   **Crucial Onboarding:** Apple requires apps to explicitly teach users how to enable extensions. You must provide a tutorial navigating them to `Settings -> Messages -> Unknown & Spam` and `Settings -> Safari -> Extensions`.
*   **App Group Setup:** Ensure `group.com.yourdomain.phishingscanner` is enabled in Capabilities so the extensions can read the SQLite file.

## Target 2: Message Filter Extension
*   **Memory Limit:** ~15MB Jetsam limit. 
*   **Database Access:** Do not use CoreData. Use raw SQLite connections or `GRDB.swift` to execute single, low-memory reads.
*   **Logic Tree:**
    1. Check if sender matches known spam list -> `.junk`.
    2. Extract URLs using `NSDataDetector`.
    3. Hash URLs (SHA-256) and check against SQLite DB -> `.junk`.
    4. If no match -> `deferQueryRequestToNetwork`.

## Target 3: Safari Web Extension
*   **Injection:** Provide a `content.js` script that runs at `document_start`.
*   **Message Passing:** Pass the URL from `content.js` to the Swift backend using `browser.runtime.sendNativeMessage`.
*   **UI Blocking:** If the Swift backend detects a threat, send a message back to `content.js` to replace the `document.body.innerHTML` with a red warning screen, removing the malicious DOM entirely.