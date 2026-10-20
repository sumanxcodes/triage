# Development Process & CI/CD Pipeline

## AI Agent Context & Directives

**Role:** You are acting as the DevSecOps and CI/CD orchestrator for this project. 
**Directive:** You must ensure all generated code, workflow files (e.g., GitHub Actions), and deployment scripts adhere strictly to the pipelines and strategies defined in this document. When suggesting commits, pull request structures, or infrastructure changes, you must enforce Conventional Commits, the GitHub Flow methodology, and our dual-stack testing requirements.

---

## 1. Source Control & Branching Strategy

This project strictly follows the **GitHub Flow** methodology combined with **Conventional Commits** to maintain a clean, automated history.

* **Main Branch (`main`):** The single source of truth. Always deployable and reflects production. Direct commits are forbidden.
* **Feature Branches:** Branched off `main`. Naming convention: `feature/short-description` (e.g., `feature/safari-extension-ui`).
* **Bugfix Branches:** Branched off `main`. Naming convention: `bugfix/issue-description` (e.g., `bugfix/redis-timeout`).
* **Commit Messages:** Must follow Conventional Commits (e.g., `feat: add GRDB sqlite wrapper`, `fix: handle null message body in ILNetworkResponse`).

## 2. Pull Request (PR) & Review Process

* All PRs must target the `main` branch.
* **Requirements for Merge:**
  * At least one approving review (if working in a team).
  * All CI checks must pass (tests, linting, build).
  * No hardcoded secrets (enforced via secret scanning).
* Squash and merge is preferred to keep the `main` history linear and clean.

## 3. iOS CI/CD Pipeline (GitHub Actions + Fastlane)

Managing provisioning profiles for an app with multiple extensions (Main App, IdentityLookup, SafariServices) is complex. **Fastlane Match** is required.

* **Continuous Integration (On PR):**
  * **Trigger:** Push to any `feature/*` or `bugfix/*` branch.
  * **Steps:**
    1. Checkout code.
    2. Run SwiftLint to enforce code style.
    3. Build the Xcode workspace (`xcodebuild`).
    4. Run XCTest unit tests (mocking SQLite DB and backend API calls).

* **Continuous Deployment (On Merge to Main):**
  * **Trigger:** Push to `main`.
  * **Steps:**
    1. Fetch provisioning profiles and certificates via `fastlane match`.
    2. Increment build number.
    3. Build release archive (`.xcarchive`).
    4. Upload to TestFlight via `fastlane pilot`.
    5. Post success notification to Slack/Discord.

## 4. Backend CI/CD Pipeline (GitHub Actions)

The backend pipeline focuses on testing the FastAPI endpoints, validating the AI worker logic, and deploying containerized updates with zero downtime.

* **Continuous Integration (On PR):**
  * **Trigger:** Changes detected in the `/backend` directory.
  * **Steps:**
    1. Setup Python environment.
    2. Run `flake8` and `mypy` for linting and type checking.
    3. Run `pytest` with a temporary SQLite DB and mocked Redis/Gemini API responses. Ensure the `< 1s` latency constraint is validated in tests.

* **Continuous Deployment (On Merge to Main):**
  * **Trigger:** Push to `main` affecting `/backend`.
  * **Steps:**
    1. Build the Docker image for the FastAPI app and Celery worker.
    2. Push image to registry (e.g., GitHub Container Registry).
    3. Trigger deployment on Fly.io or Render via CLI (e.g., `flyctl deploy`).
    4. Run database migrations (`alembic upgrade head`).

## 5. Local Development Environment

To ensure a smooth onboarding process for new developers or AI agents:

* **iOS:** Use standard Xcode. Dependencies managed via Swift Package Manager (SPM).
* **Backend:** Include a `docker-compose.yml` in the repository root that instantly spins up local instances of:
  * PostgreSQL (Database)
  * Redis (Cache)
  * FastAPI Server (Hot-reloading via Uvicorn)
  * Celery Worker
  * *Note:* Developers will need to supply their own `.env` file with a valid `GEMINI_API_KEY`.