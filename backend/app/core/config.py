from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "Triage Threat Intelligence API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # In-memory Redis Cache for < 1s lookup
    REDIS_URL: str = "redis://localhost:6379/0"

    # PostgreSQL Database
    DATABASE_URL: str = "postgresql://triage:triage@localhost:5432/triage_db"

    # Celery Broker / Backend
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # Google Gemini API
    GEMINI_API_KEY: str = ""

    # Threat Intelligence Feeds & Ethics Configuration
    THREAT_INTEL_USER_AGENT: str = (
        "Triage-Threat-Intel/1.0 (+https://triage.security; research@triage.security)"
    )
    URLHAUS_AUTH_KEY: str = ""
    URLHAUS_RECENT_URL: str = "https://urlhaus-api.abuse.ch/v1/urls/recent/"
    OPENPHISH_FEED_URL: str = "https://openphish.com/feed.txt"
    PHISHING_ARMY_FEED_URL: str = "https://phishing.army/download/phishing_army_blocklist_extended.txt"
    FEED_RETENTION_DAYS: int = 14
    FEED_BATCH_SIZE: int = 500

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


settings = Settings()
