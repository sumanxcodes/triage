# Triage Backend

FastAPI Threat Intelligence Gateway & Celery AI Worker pipeline.

## Features
- **Stateless SMS Filter:** `< 1s` latency threat hash lookup for iOS `IdentityLookup`.
- **Zero-Day Pipeline:** Background Celery worker running Playwright and Google Gemini heuristic analysis.
- **Threat Delta Sync:** Endpoint for iOS client local SQLite database updates.

## Development Setup
```bash
# Using uv:
uv venv
source .venv/bin/activate
uv pip install -e ".[dev]"

# Run tests:
pytest
```
