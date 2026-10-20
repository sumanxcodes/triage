# Project: Triage

**Tagline:** A privacy-first, dual-layer SMS and Link Phishing Scanner for iOS.

## 1. Project Overview
**Triage** is an iOS application and backend threat-intelligence service designed to protect users from "smishing" (SMS phishing) and malicious zero-day URLs. Operating under strict Apple sandbox constraints, Triage utilizes a defense-in-depth approach: it intercepts unknown spam at the inbox level and provides a safety net at the browser level for compromised known contacts.

## 2. Core Features
* **SMS Triage (Inbox Protection):** Uses iOS `IdentityLookup` to silently filter inbound SMS messages from unknown senders into Junk, Transactional, or Promotional folders.
* **Link Triage (Browser Protection):** Uses an iOS Safari Web Extension to intercept navigation, blocking known malicious URLs before the DOM renders.
* **Zero-Day AI Analysis:** If a user navigates to an unknown but suspicious URL, the Safari extension safely reports it to the backend where an AI agent (Gemini) evaluates the live webpage in a headless browser, updating the global threat list in real-time.
* **Privacy-First Operations:** The iOS app operates primarily via a locally synced SQLite database. Live network lookups are fully anonymized, and message payloads are never logged on the server.

## 3. The Tech Stack Snapshot
* **iOS Client:** Swift 5+, SwiftUI, `IdentityLookup`, `SafariServices`, `GRDB.swift`.
* **Backend API:** Python, FastAPI, Redis (Sub-second Cache), PostgreSQL (Main DB).
* **AI Worker Pipeline:** Celery, Playwright (Headless Scraping), Google Gemini API.

## 4. AI Agent System Context
*If you are an AI agent assisting with this repository, read this section carefully:*
* **Primary Constraint:** You must respect Apple's App Store Review Guidelines regarding privacy. We cannot view SMS messages from the user's saved contacts. We cannot log or store user message data on our backend.
* **Performance Constraint:** Any live URL lookup via `ILNetworkResponse` must resolve in under 1 second to prevent iOS from timing out.
* **Documentation Links:** 
  * See `01_agent_system_prompt.md` for your detailed persona and constraints.
  * See `02_system_architecture.md` for data flows.
  * See `03_ios_client_spec.md` for Swift/iOS implementation.
  * See `04_backend_ai_spec.md` for Python/FastAPI implementation.
  * See `05_development_process_cicd.md` for our GitHub Flow and deployment rules.