from celery import Celery
from app.core.config import settings

celery_app = Celery(
    "triage_worker",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=60,  # Playwright scrapers should not run longer than 60s
    beat_schedule={
        "ingest-urlhaus-every-30-mins": {
            "task": "ingest_urlhaus_feed_task",
            "schedule": 1800.0,
            "args": (1000,),
        },
        "ingest-openphish-every-6-hours": {
            "task": "ingest_openphish_feed_task",
            "schedule": 21600.0,
            "args": (1000,),
        },
        "prune-stale-threats-daily": {
            "task": "prune_stale_threats_task",
            "schedule": 86400.0,
            "args": (14,),
        },
    },
)
