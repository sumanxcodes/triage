.PHONY: help test-backend lint-backend dev-backend docker-up docker-down ios-generate test-all

help:
	@echo "Triage Monorepo Commands:"
	@echo "  make test-backend   - Run backend unit tests with pytest"
	@echo "  make lint-backend   - Run flake8 and mypy checks"
	@echo "  make dev-backend    - Start local FastAPI dev server with hot reload"
	@echo "  make docker-up      - Spin up Redis, Postgres, API, and Celery via Docker"
	@echo "  make docker-down    - Tear down local Docker containers"
	@echo "  make ios-generate   - Regenerate iOS Xcode project via XcodeGen"
	@echo "  make test-all       - Run all backend tests and linting"

test-backend:
	cd backend && .venv/bin/pytest -v

lint-backend:
	cd backend && .venv/bin/flake8 . && .venv/bin/mypy app worker

dev-backend:
	cd backend && .venv/bin/uvicorn app.main:app --reload --port 8000

docker-up:
	cd backend && docker compose up -d

docker-down:
	cd backend && docker compose down

ios-generate:
	cd ios && xcodegen generate

test-all: lint-backend test-backend
