# Triage Project Implementation Checklist & Progress Tracker

> **Last Updated:** October 20, 2026  
> **Status:** Phase 1 (Foundation & Core SMS Threat Engine) Completed

---

## 🗺️ Milestone Overview

| Milestone | Description | Status |
| :--- | :--- | :---: |
| **M1: Repository & Standards** | Monorepo structure, Git/SSH setup, specs numbering, Makefile, README | ✅ Completed |
| **M2: CI/CD Pipelines** | Path-filtered GitHub Actions (Linux for backend, macOS/Xcode 16.2 for iOS) | ✅ Completed |
| **M3: Flow B — SMS Threat Engine** | Anti-obfuscation normalizer, sub-second shortlink resolver, Redis cache pipeline | ✅ Completed |
| **M4: Native iOS Multi-Target** | Declarative XcodeGen, App Group GRDB SQLite DB, IdentityLookup & Safari extensions | ✅ Completed |
| **M5: Flow C — Zero-Day AI Pipeline** | Playwright headless browser scraper, Google Gemini multimodal prompt evaluation | ⏳ Next Up |
| **M6: Flow A — Offline Sync & DB** | PostgreSQL Alembic models, `/api/v1/threats/delta`, iOS `BGTaskScheduler` sync | 📋 Planned |
| **M7: App Store & TestFlight** | StoreKit 2 subscriptions, Fastlane Match & Pilot, privacy manifests | 📋 Planned |

---

## ✅ Completed Tasks

### 1. Repository & Developer Tooling
- [x] Initialized Git repository on `main` branch with SSH remote configuration (`github-sumanxcodes`).
- [x] Standardized specification documentation under [`docs/`](./).
- [x] Created root [`Makefile`](../Makefile) with developer convenience targets:
  - `make test-backend`: Runs Pytest suite.
  - `make lint-backend`: Runs Flake8 and Mypy.
  - `make dev-backend`: Runs local FastAPI hot-reload server.
  - `make docker-up` / `make docker-down`: Manages local Redis and Postgres containers.
  - `make ios-generate`: Generates Xcode project via XcodeGen.
  - `make test-all`: Runs full validation suite.
- [x] Added root [`README.md`](../README.md) and comprehensive [`.gitignore`](../.gitignore).

### 2. Isolated CI/CD Pipelines
- [x] Isolated backend workflow ([`.github/workflows/backend-ci.yml`](../.github/workflows/backend-ci.yml)):
  - Triggers only on `backend/**`, `shared/**`, or workflow changes.
  - Runs on Ubuntu with containerized Redis service.
  - Executes Flake8, Mypy, and Pytest.
- [x] Isolated iOS workflow ([`.github/workflows/ios-ci.yml`](../.github/workflows/ios-ci.yml)):
  - Triggers only on `ios/**`, `shared/**`, or workflow changes.
  - Runs on `macos-14` (Apple Silicon) with **Xcode 16.2** toolchain to support project format 77.
  - Installs XcodeGen, generates project, and validates `xcodebuild` compilation.
- [x] Created shared cross-stack test vectors:
  - [`shared/mock_sms_payloads.json`](../shared/mock_sms_payloads.json) (Punycode, homoglyphs, shortlinks, tracking evasion, clean OTPs).
  - [`shared/mock_threat_urls.json`](../shared/mock_threat_urls.json) (Pre-hashed known phishing targets).

### 3. Backend Threat Intelligence API & Engine (`backend/`)
- [x] Managed dependencies via `uv` ([`backend/pyproject.toml`](../backend/pyproject.toml)) and configured linting ([`backend/.flake8`](../backend/.flake8)).
- [x] Created containerized local environment ([`backend/docker-compose.yml`](../backend/docker-compose.yml) and [`backend/Dockerfile`](../backend/Dockerfile)).
- [x] Built FastAPI application entrypoint with lifespan Redis management ([`backend/app/main.py`](../backend/app/main.py)):
  - `GET /health`: Service health check.
  - `GET /api/v1/threats/delta`: Delta sync route stub.
  - `POST /api/v1/safari/scan`: Browser link scan route.
- [x] Built **SMS Anti-Obfuscation Normalizer** ([`backend/app/core/normalizer.py`](../backend/app/core/normalizer.py)):
  - Punycode & IDN decoding (protects against lookalike homoglyphs like `xn--pple-43d.com`).
  - Obfuscated IP address normalization (dword, hex, octal $\to$ dotted decimal).
  - Tracking parameter stripping (`utm_*`, `fbclid`, `gclid`, etc.).
  - Deterministic parameter sorting and port/fragment stripping.
  - Multi-key hash generation (canonical URL, registered domain, and host hashes).
- [x] Built **Sub-Second Shortlink Resolver** ([`backend/app/core/resolver.py`](../backend/app/core/resolver.py)):
  - Unrolls `bit.ly`, `tinyurl.com`, `t.co`, etc., via HTTP `HEAD` with strict 250ms timeout.
- [x] Built **Redis Threat Cache** ([`backend/app/core/threat_cache.py`](../backend/app/core/threat_cache.py)):
  - O(1) multi-key pipeline lookups via `MGET` across URL, domain, and sender keys.
  - Threat seeding and ingestion utilities.
- [x] Built **Stateless SMS Filter Endpoint** ([`backend/app/api/v1/sms.py`](../backend/app/api/v1/sms.py)):
  - Stateless processing complying with Apple Privacy Guidelines (no message logging).
  - Sub-second latency guarantee (< 50ms average in benchmarks).
- [x] Configured Celery worker skeleton ([`backend/worker/celery_app.py`](../backend/worker/celery_app.py), [`backend/worker/tasks.py`](../backend/worker/tasks.py)).
- [x] Achieved 100% test coverage on SMS engine (14 tests in 0.04s, Flake8 & Mypy 100% clean).

### 4. Native iOS Multi-Target Architecture (`ios/`)
- [x] Declarative project spec ([`ios/project.yml`](../ios/project.yml)) generating clean `Triage.xcodeproj`.
- [x] Created shared App Group module ([`ios/TriageShared/`](../ios/TriageShared)):
  - [`ThreatDatabase.swift`](../ios/TriageShared/Database/ThreatDatabase.swift): `GRDB.swift` SQLite engine with WAL mode and indexed O(1) multi-hash lookups.
  - [`ThreatRecord.swift`](../ios/TriageShared/Database/ThreatRecord.swift): Codable persistable SQLite record.
  - [`AppGroup.swift`](../ios/TriageShared/Utils/AppGroup.swift): Security container URL manager (`group.com.sumanxcodes.triage`).
  - [`URLHasher.swift`](../ios/TriageShared/Utils/URLHasher.swift): Native Swift URL canonicalization, tracking parameter stripping, and candidate hash generation.
- [x] Built **Main App Target** ([`ios/TriageApp/`](../ios/TriageApp)):
  - SwiftUI entrypoint and security status dashboard.
  - Mandatory onboarding view ([`OnboardingView.swift`](../ios/TriageApp/OnboardingView.swift)) guiding users through Settings configuration.
  - App Group entitlements.
- [x] Built **Message Filter Extension Target** ([`ios/TriageMessageFilter/`](../ios/TriageMessageFilter)):
  - `ILMessageFilterExtension` conforming to `ILMessageFilterQueryHandling`.
  - Memory-safe (<15MB Jetsam limit) local SQLite check $\to$ deferred network lookup.
- [x] Built **Safari Web Extension Target** ([`ios/TriageSafariExtension/`](../ios/TriageSafariExtension)):
  - `SafariWebExtensionHandler.swift` native message handler.
  - Manifest V3 configuration and `content.js` executing at `document_start`.
  - Full-page blocking warning interstitial preventing malicious DOM execution.
- [x] Configured Fastlane pipeline ([`ios/Fastfile`](../ios/Fastfile)) for linting, scanning, and TestFlight deployment.

---

## ⏳ Next Up: Flow C — Zero-Day AI Pipeline

- [ ] **Playwright Headless Scraper (`backend/worker/tasks.py`):**
  - Implement full Chromium headless navigation to incoming suspicious URLs.
  - Extract DOM structure, forms, inputs (password/credit card fields), page title, and external asset origins.
  - Capture rendered page screenshot for visual comparison.
- [ ] **Google Gemini API Evaluation:**
  - Design prompt evaluating DOM heuristic signals + screenshot for brand imitation.
  - Output structured JSON: `{ "is_phishing": bool, "target_brand": str, "confidence": float, "reasons": [] }`.
- [ ] **Threat Publishing:**
  - Auto-publish confirmed phishing URLs to Redis (`threat:url:<hash>`) and PostgreSQL so the entire user base is protected within seconds.
- [ ] **Safari Extension Polling / WebSocket Interstitial:**
  - Connect iOS Safari interstitial to stream live analysis status while the AI worker evaluates zero-day links.

---

## 📋 Future Milestones

### Flow A: Offline Sync & PostgreSQL Threat Store
- [ ] Design PostgreSQL threat table schema with Alembic migrations.
- [ ] Implement `GET /api/v1/threats/delta` with incremental timestamp pagination.
- [ ] Implement iOS `BGTaskScheduler` background worker to sync deltas into GRDB SQLite.

### App Store Readiness & Polish
- [ ] StoreKit 2 paywall implementation (subscription plans & receipt validation).
- [ ] Apple Privacy Manifests (`PrivacyInfo.xcprivacy`) for extensions and main app.
- [ ] TestFlight CI/CD automation via Fastlane Match.
