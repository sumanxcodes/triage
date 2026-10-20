# Triage

> A privacy-first, dual-layer SMS and Link Phishing Scanner for iOS.

[![Backend CI](https://github.com/sumanxcodes/triage/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/sumanxcodes/triage/actions/workflows/backend-ci.yml)
[![iOS CI](https://github.com/sumanxcodes/triage/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/sumanxcodes/triage/actions/workflows/ios-ci.yml)

## Architecture Overview

Triage utilizes a defense-in-depth approach operating under strict Apple sandbox constraints:
1. **SMS Triage (Inbox Protection):** Intercepts unknown senders using `IdentityLookup`, executing single, low-memory reads on a local `GRDB.swift` SQLite database (~15MB memory budget) and falling back to a stateless `< 1s` backend API lookup.
2. **Link Triage (Browser Protection):** Intercepts navigation via a Safari Web Extension, halting DOM execution and replacing malicious pages before they render.
3. **Zero-Day AI Analysis:** Unknown links are submitted asynchronously to a Celery worker that scrapes the DOM with Playwright and classifies the threat using Google Gemini.

```
triage/
├── .github/
│   └── workflows/
│       ├── ios-ci.yml           # Runs only on changes to ios/**
│       └── backend-ci.yml       # Runs only on changes to backend/**
├── docs/                        # Architecture & agent specifications
│   ├── 01_agent_system_prompt.md
│   ├── 02_system_architecture.md
│   ├── 03_ios_client_spec.md
│   ├── 04_backend_ai_spec.md
│   ├── 05_development_process_cicd.md
│   └── project_overview_metadata.md
├── shared/                      # Shared test vectors & mock payloads
│   ├── mock_sms_payloads.json
│   └── mock_threat_urls.json
├── ios/                         # Native iOS Workspace (Swift 5+ / SwiftUI)
│   ├── project.yml              # XcodeGen declarative project configuration
│   ├── Triage.xcodeproj         # Generated Xcode project
│   ├── TriageApp/               # Main SwiftUI application target
│   ├── TriageMessageFilter/     # IdentityLookup SMS extension target
│   ├── TriageSafariExtension/   # SafariServices web extension target
│   ├── TriageShared/            # Shared GRDB models, SQLite manager & URL hashers
│   └── Fastfile                 # Fastlane match and TestFlight deployment
├── backend/                     # Python/FastAPI Threat Intelligence Service
│   ├── app/                     # Stateless FastAPI API & Redis cache layer
│   ├── worker/                  # Celery worker (Playwright + Gemini AI pipeline)
│   ├── tests/                   # Pytest test suite with < 1s latency assertions
│   ├── Dockerfile               # Container definition
│   ├── docker-compose.yml       # Local Redis, Postgres, API, and Celery stack
│   └── pyproject.toml           # Project dependencies via uv / pip
├── Makefile                     # Root development shortcuts
└── .gitignore
```

---

## Quickstart

### 1. Backend Development

Requirements: `uv` (recommended) or `python >= 3.11`, `docker`.

```bash
# Setup backend virtual environment and install dependencies:
cd backend
uv venv
source .venv/bin/activate
uv pip install -e ".[dev]"

# Spin up local Redis & PostgreSQL:
docker compose up -d redis postgres

# Run backend tests:
pytest -v

# Start FastAPI dev server with auto-reload:
uvicorn app.main:app --reload --port 8000
```

### 2. iOS Development

Requirements: macOS with Xcode 15+, `xcodegen`.

```bash
# Install XcodeGen if not installed:
brew install xcodegen

# Generate Xcode project:
cd ios
xcodegen generate

# Open project in Xcode:
open Triage.xcodeproj
```

### 3. Root Developer Shortcuts

```bash
make test-backend   # Run backend tests
make lint-backend   # Run flake8 and mypy
make ios-generate   # Regenerate Xcode project
make docker-up      # Start Docker services
```
