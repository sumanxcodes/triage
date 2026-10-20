import json
import logging
from typing import Any, Dict, List, Optional, Tuple
import redis.asyncio as aioredis

logger = logging.getLogger(__name__)


async def check_threat_hashes(
    redis: aioredis.Redis,
    candidate_keys: List[Tuple[str, str]],
    sender: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    """
    Executes a sub-millisecond Redis pipeline checking multi-level candidate keys:
    Returns the first matching threat metadata dict, or None if clean.
    """
    redis_keys = []
    for prefix, hash_val in candidate_keys:
        redis_keys.append(f"threat:{prefix}:{hash_val}")

    if sender:
        cleaned_sender = sender.strip().replace(" ", "").lower()
        redis_keys.append(f"threat:sender:{cleaned_sender}")

    if not redis_keys:
        return None

    # Use MGET for single O(N) roundtrip read
    values = await redis.mget(redis_keys)
    for val in values:
        if val is not None:
            try:
                parsed = json.loads(val)
                if isinstance(parsed, dict):
                    return parsed
                return {"type": "phishing", "status": "blocked"}
            except Exception:
                return {"type": "phishing", "status": "blocked"}

    return None


async def add_threat_entry(
    redis: aioredis.Redis,
    prefix: str,
    key_value: str,
    metadata: Dict[str, Any],
    ttl_seconds: Optional[int] = None,
) -> None:
    """Store a threat record in Redis."""
    redis_key = f"threat:{prefix}:{key_value}"
    payload = json.dumps(metadata)
    if ttl_seconds:
        await redis.setex(redis_key, ttl_seconds, payload)
    else:
        await redis.set(redis_key, payload)


async def seed_threat_database(
    redis: aioredis.Redis,
    mock_threats: List[Dict[str, Any]],
) -> int:
    """Seed threat URLs and domain hashes from a list of threat records."""
    from app.core.normalizer import canonicalize_url, generate_threat_lookup_keys

    count = 0
    pipe = redis.pipeline()
    for item in mock_threats:
        url = item.get("url")
        if not url:
            continue

        canonical = canonicalize_url(url)
        keys = generate_threat_lookup_keys(canonical)

        metadata = {
            "threat_type": item.get("threat_type", "phishing"),
            "target_brand": item.get("target_brand", "Unknown"),
            "confidence_score": item.get("confidence_score", 1.0),
        }
        meta_json = json.dumps(metadata)

        # Store URL hash
        for prefix, h in keys:
            pipe.set(f"threat:{prefix}:{h}", meta_json)
            count += 1

        # Also store provided sha256 directly under legacy format for backward compatibility
        if "sha256" in item:
            pipe.set(f"threat:{item['sha256']}", meta_json)
            pipe.set(f"threat:url:{item['sha256']}", meta_json)

    await pipe.execute()
    return count
