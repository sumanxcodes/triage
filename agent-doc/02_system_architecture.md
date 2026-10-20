# System Architecture & Tech Stack

## Technology Stack
*   **iOS Client:** Swift 5+, SwiftUI (App), `IdentityLookup` (SMS Extension), `SafariServices` (Web Extension).
*   **Local Database:** `GRDB.swift` (SQLite) shared via iOS App Groups.
*   **API Gateway:** Python / FastAPI hosted on Fly.io or Render (for low-latency edge deployment).
*   **Fast Cache:** Upstash or self-hosted Redis (Sub-millisecond lookups for SMS API).
*   **Main Database:** Supabase / PostgreSQL (Master threat lists, user subscriptions).
*   **Background Worker:** Python / Celery (handles heavy AI processing asynchronously).
*   **AI Engine:** Playwright (DOM scraping) + Google Gemini API (Heuristic evaluation).

## Core Data Flows

### Flow A: Offline Database Synchronization
1. Main iOS App awakes via Background Tasks.
2. App queries `GET /api/v1/threats/delta`.
3. FastAPI queries PostgreSQL for new threat hashes added in the last 24 hours.
4. App writes new hashes to the shared SQLite database using `GRDB.swift`.

### Flow B: Unknown SMS Intercept
1. iOS receives SMS from an unknown number.
2. iOS invokes `ILMessageFilterExtension`.
3. Extension queries shared SQLite DB. If a match is found -> returns `.junk`.
4. If inconclusive, Extension calls `deferQueryRequestToNetwork()`.
5. iOS sends HTTPS POST with `{"messageBody": "...", "sender": "..."}` to FastAPI.
6. FastAPI extracts URLs, hashes them, and checks Redis.
7. FastAPI returns `{"action": "junk"}` or `{"action": "none"}` within < 1 second. Data is dropped from RAM.

### Flow C: Safari Link Click & Zero-Day Analysis
1. User clicks a link. Safari Web Extension intercepts the `window.location.href`.
2. Swift handler checks local SQLite DB.
3. If unknown, Extension injects a local HTML "Scanning..." interstitial.
4. Extension pings FastAPI: `POST /api/v1/safari/scan`.
5. FastAPI passes URL to Celery Worker and immediately returns a `202 Accepted` (polling) or holds connection for WebSocket/SSE.
6. Celery Worker uses Playwright to scrape DOM, passes to Gemini API.
7. If Gemini flags as Phishing -> URL added to Postgres & Redis -> Frontend updates interstitial to "Blocked".