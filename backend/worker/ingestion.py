import asyncio
from datetime import datetime, timedelta, timezone
import json
import logging
from typing import Any, Dict, List, Optional
from urllib.parse import urlsplit

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.normalizer import canonicalize_url, extract_registered_domain, generate_threat_lookup_keys
from app.core.whitelist import can_block_domain, is_candidate_url_safe_to_ingest
from app.db.models import ThreatRecordModel
from app.db.session import async_session_factory
from worker.feeds.base import FeedThreatItem
from worker.feeds.openphish import OpenPhishCollector
from worker.feeds.urlhaus import URLhausCollector

logger = logging.getLogger(__name__)


def get_sync_redis():
    """Returns a synchronous Redis connection for caching threat hashes."""
    try:
        import redis
        return redis.Redis.from_url(settings.REDIS_URL, decode_responses=True)
    except Exception as e:
        logger.warning(f"Could not connect to Redis: {e}")
        return None


async def ingest_threat_items(
    items: List[FeedThreatItem],
    session: Optional[AsyncSession] = None,
) -> Dict[str, int]:
    """
    Ingests and normalizes feed threat items with safety whitelisting,
    scope isolation, database upserts, and Redis caching.
    """
    stats = {
        "received": len(items),
        "skipped_whitelist": 0,
        "inserted": 0,
        "updated": 0,
        "deactivated": 0,
    }

    if not items:
        return stats

    r = get_sync_redis()
    owns_session = session is None
    db = session if session is not None else async_session_factory()

    try:
        async with db as s:
            for item in items:
                # 1. Safety Whitelist check
                if not is_candidate_url_safe_to_ingest(item.raw_url):
                    stats["skipped_whitelist"] += 1
                    continue

                canonical = canonicalize_url(item.raw_url)
                if not is_candidate_url_safe_to_ingest(canonical):
                    stats["skipped_whitelist"] += 1
                    continue

                # 2. Scope Isolation & Hash Generation
                keys = generate_threat_lookup_keys(canonical)
                url_hash = keys[0][1]

                parts = urlsplit(canonical)
                host = parts.netloc.split(":")[0].strip().lower()
                reg_domain = extract_registered_domain(host)

                # Scope isolation: If multi-tenant or shared cloud, DO NOT block domain
                domain_allowed = can_block_domain(reg_domain)
                domain_hash = keys[1][1] if domain_allowed else url_hash

                # 3. Database Upsert
                query = select(ThreatRecordModel).where(ThreatRecordModel.url_hash == url_hash)
                result = await s.execute(query)
                existing = result.scalar_one_or_none()

                now = datetime.now(timezone.utc)
                if existing:
                    existing.is_active = item.is_online
                    existing.threat_type = item.threat_type
                    existing.confidence_score = item.confidence_score
                    if item.target_brand:
                        existing.target_brand = item.target_brand
                    existing.updated_at = now
                    stats["updated"] += 1
                else:
                    new_record = ThreatRecordModel(
                        url_hash=url_hash,
                        domain_hash=domain_hash,
                        canonical_url=canonical,
                        threat_type=item.threat_type,
                        target_brand=item.target_brand,
                        source=item.source,
                        confidence_score=item.confidence_score,
                        is_active=item.is_online,
                        created_at=item.added_at,
                        updated_at=now,
                    )
                    s.add(new_record)
                    stats["inserted"] += 1

                # 4. Redis Cache Updating
                if r is not None:
                    try:
                        if item.is_online:
                            threat_meta = json.dumps({
                                "threat_type": item.threat_type,
                                "target_brand": item.target_brand or "Unknown",
                                "confidence_score": item.confidence_score,
                                "source": item.source,
                            })
                            r.set(f"threat:url:{url_hash}", threat_meta)
                            r.set(f"threat:{url_hash}", threat_meta)
                            if domain_allowed:
                                r.set(f"threat:domain:{domain_hash}", threat_meta)
                        else:
                            r.delete(f"threat:url:{url_hash}", f"threat:{url_hash}")
                            if domain_allowed:
                                r.delete(f"threat:domain:{domain_hash}")
                    except Exception as redis_err:
                        logger.warning(f"Failed to update Redis cache: {redis_err}")

            await s.commit()

    finally:
        if owns_session and hasattr(db, "close"):
            await db.close()

    logger.info(
        f"Ingestion completed. Inserted: {stats['inserted']}, "
        f"Updated: {stats['updated']}, Skipped by Whitelist: {stats['skipped_whitelist']}"
    )
    return stats


async def prune_stale_threats(retention_days: int = 14) -> int:
    """
    Deactivates threats older than the retention window (e.g. 14 days).
    Deactivated threats are emitted in delta sync as removed_hashes so iOS clients prune them.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)
    pruned_count = 0

    r = get_sync_redis()
    async with async_session_factory() as s:
        # Select active threats older than retention cutoff (excluding manual seeds)
        query = (
            select(ThreatRecordModel)
            .where(ThreatRecordModel.is_active.is_(True))
            .where(ThreatRecordModel.updated_at < cutoff)
            .where(ThreatRecordModel.source != "manual")
        )
        result = await s.execute(query)
        stale_records = result.scalars().all()

        now = datetime.now(timezone.utc)
        for rec in stale_records:
            rec.is_active = False
            rec.updated_at = now
            pruned_count += 1

            if r is not None:
                try:
                    r.delete(f"threat:url:{rec.url_hash}", f"threat:{rec.url_hash}")
                    r.delete(f"threat:domain:{rec.domain_hash}")
                except Exception:
                    pass

        await s.commit()

    logger.info(f"Pruned {pruned_count} stale threats older than {retention_days} days.")
    return pruned_count


async def run_feed_pipeline(feed_name: str, limit: Optional[int] = None) -> Dict[str, Any]:
    """Runs a single feed ingestion collector and ingestion pipeline."""
    collector: URLhausCollector | OpenPhishCollector
    if feed_name == "urlhaus":
        collector = URLhausCollector()
    elif feed_name == "openphish":
        collector = OpenPhishCollector()
    else:
        raise ValueError(f"Unknown feed name: {feed_name}")

    threats = await collector.fetch_threats(limit=limit)
    stats: Dict[str, Any] = await ingest_threat_items(threats)
    stats["feed"] = feed_name
    return stats


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Triage Threat Feed Ingestion CLI")
    parser.add_argument("--feed", choices=["urlhaus", "openphish", "all"], default="urlhaus")
    parser.add_argument("--limit", type=int, default=50, help="Max threats to fetch")
    parser.add_argument("--prune", action="store_true", help="Run stale threat pruning")
    args = parser.parse_args()

    async def main():
        if args.prune:
            count = await prune_stale_threats()
            print(f"Pruned {count} stale threats.")
            return

        if args.feed in ("urlhaus", "all"):
            print(f"Running URLhaus ingestion (limit={args.limit})...")
            res = await run_feed_pipeline("urlhaus", limit=args.limit)
            print(f"URLhaus Result: {res}")

        if args.feed in ("openphish", "all"):
            print(f"Running OpenPhish ingestion (limit={args.limit})...")
            res = await run_feed_pipeline("openphish", limit=args.limit)
            print(f"OpenPhish Result: {res}")

    asyncio.run(main())
