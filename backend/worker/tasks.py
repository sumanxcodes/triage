import asyncio
import json
import logging
from typing import Any, Dict, List
import redis

from app.core.config import settings
from app.core.normalizer import canonicalize_url, generate_threat_lookup_keys
from worker.analyzer import PhishingAnalysisResult, evaluate_with_gemini
from worker.celery_app import celery_app
from worker.scraper import scrape_url_headless

logger = logging.getLogger(__name__)


def get_sync_redis() -> redis.Redis:
    """Synchronous Redis client for Celery tasks."""
    return redis.Redis.from_url(settings.REDIS_URL, decode_responses=True)


async def async_save_threat_record(
    canonical: str,
    verdict: PhishingAnalysisResult,
    keys: List[tuple],
) -> None:
    """Persists a confirmed threat record to PostgreSQL asynchronously."""
    try:
        from app.db.models import ThreatRecordModel
        from app.db.session import async_session_factory

        url_hash = keys[0][1]
        domain_hash = keys[1][1] if len(keys) > 1 else url_hash

        async with async_session_factory() as session:
            record = ThreatRecordModel(
                url_hash=url_hash,
                domain_hash=domain_hash,
                canonical_url=canonical,
                threat_type=verdict.threat_category,
                target_brand=verdict.target_brand,
                source="gemini_zero_day",
                confidence_score=verdict.confidence_score,
                is_active=True,
            )
            session.add(record)
            await session.commit()
    except Exception as e:
        logger.warning(f"Could not persist threat to PostgreSQL: {e}")


@celery_app.task(name="analyze_urls_zero_day", bind=True)
def analyze_urls_zero_day(self, urls: List[str]) -> Dict[str, Any]:
    """
    Background worker task:
    1. Launches Playwright headless browser to render page & scrape DOM heuristics.
    2. Sends rendered visual & text artifacts to Google Gemini API for classification.
    3. If flagged as phishing, publishes threat hashes to Redis cache immediately.
    """
    results: Dict[str, Any] = {}

    try:
        r = get_sync_redis()
    except Exception as e:
        logger.warning(f"Could not connect to Redis in worker: {e}")
        r = None

    for raw_url in urls:
        canonical = canonicalize_url(raw_url)
        logger.info(f"Analyzing zero-day URL: {canonical}")

        # 1. Scrape DOM & capture screenshot with Playwright
        scraped = scrape_url_headless(canonical, timeout_ms=15000)

        # 2. Evaluate with Google Gemini (or heuristic fallback)
        verdict = evaluate_with_gemini(scraped)

        result_payload = {
            "url": canonical,
            "final_url": scraped.final_url,
            "is_phishing": verdict.is_phishing,
            "target_brand": verdict.target_brand,
            "threat_category": verdict.threat_category,
            "confidence_score": verdict.confidence_score,
            "reasons": verdict.reasons,
        }
        results[canonical] = result_payload

        # 3. If classified as phishing with high confidence, auto-publish to Redis
        if verdict.is_phishing and verdict.confidence_score >= 0.7 and r is not None:
            try:
                keys = generate_threat_lookup_keys(canonical)
                threat_meta = json.dumps({
                    "threat_type": verdict.threat_category,
                    "target_brand": verdict.target_brand or "Unknown",
                    "confidence_score": verdict.confidence_score,
                    "detected_by": "gemini_zero_day_worker",
                })

                pipe = r.pipeline()
                for prefix, hash_val in keys:
                    # Write threat key (e.g. threat:url:<hash>, threat:domain:<hash>)
                    pipe.set(f"threat:{prefix}:{hash_val}", threat_meta)
                    # Also write legacy format
                    if prefix == "url":
                        pipe.set(f"threat:{hash_val}", threat_meta)

                # Cache full verdict under analysis key for 24h
                url_hash = keys[0][1]
                pipe.setex(f"analysis:url:{url_hash}", 86400, json.dumps(result_payload))
                pipe.execute()

                # Persist to PostgreSQL master database for client delta synchronization
                try:
                    asyncio.run(async_save_threat_record(canonical, verdict, keys))
                except Exception as db_err:
                    logger.warning(f"Failed to persist threat to database: {db_err}")

                logger.info(f"Published confirmed zero-day threat: {canonical} ({verdict.target_brand})")
            except Exception as e:
                logger.error(f"Failed to publish threat to Redis: {e}")

    return results


@celery_app.task(name="ingest_urlhaus_feed_task")
def ingest_urlhaus_feed_task(limit: int = 1000) -> Dict[str, Any]:
    """Periodic task: Ingests online malware URLs from URLhaus (abuse.ch)."""
    from worker.ingestion import run_feed_pipeline
    logger.info("Starting scheduled URLhaus feed ingestion task.")
    return asyncio.run(run_feed_pipeline("urlhaus", limit=limit))


@celery_app.task(name="ingest_openphish_feed_task")
def ingest_openphish_feed_task(limit: int = 1000) -> Dict[str, Any]:
    """Periodic task: Ingests active phishing URLs from OpenPhish."""
    from worker.ingestion import run_feed_pipeline
    logger.info("Starting scheduled OpenPhish feed ingestion task.")
    return asyncio.run(run_feed_pipeline("openphish", limit=limit))


@celery_app.task(name="prune_stale_threats_task")
def prune_stale_threats_task(retention_days: int = 14) -> Dict[str, Any]:
    """Periodic task: Deactivates stale threats older than retention window for client sync pruning."""
    from worker.ingestion import prune_stale_threats
    logger.info(f"Starting scheduled stale threat pruning task (retention={retention_days}d).")
    pruned = asyncio.run(prune_stale_threats(retention_days=retention_days))
    return {"pruned_count": pruned, "retention_days": retention_days}
