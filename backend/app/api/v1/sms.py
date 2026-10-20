import asyncio
from typing import List, Tuple
from fastapi import APIRouter, Depends
import redis.asyncio as aioredis

from app.core.normalizer import (
    canonicalize_url,
    extract_raw_urls,
    generate_threat_lookup_keys,
    is_shortener,
)
from app.core.redis import get_redis
from app.core.resolver import resolve_shortlink
from app.core.threat_cache import check_threat_hashes
from app.schemas.sms import AppleMessageFilterRequest, AppleMessageFilterResponse, FilterAction
from worker.celery_app import celery_app

router = APIRouter(prefix="/sms", tags=["SMS Filter"])


@router.post("/filter", response_model=AppleMessageFilterResponse)
async def filter_sms(
    payload: AppleMessageFilterRequest,
    redis: aioredis.Redis = Depends(get_redis),
) -> AppleMessageFilterResponse:
    """
    Apple IdentityLookup Network Endpoint:
    - Strict Privacy Rule: Completely stateless. Do not log `messageBody` or `sender`.
    - Strict Performance Requirement: Must respond in < 1 second.
    """
    if not payload.messageBody:
        return AppleMessageFilterResponse(action=FilterAction.NONE)

    # 1. Extract raw URLs
    raw_urls = extract_raw_urls(payload.messageBody)
    if not raw_urls:
        # Check sender-based block if provided
        if payload.sender:
            sender_match = await check_threat_hashes(redis, [], sender=payload.sender)
            if sender_match:
                return AppleMessageFilterResponse(action=FilterAction.FILTER)
        return AppleMessageFilterResponse(action=FilterAction.NONE)

    # 2. Canonicalize extracted URLs & generate multi-key lookup targets
    candidate_keys: List[Tuple[str, str]] = []
    canonical_urls: List[str] = []

    for raw_url in raw_urls:
        canonical = canonicalize_url(raw_url)
        canonical_urls.append(canonical)
        candidate_keys.extend(generate_threat_lookup_keys(canonical))

    # 3. Handle URL Shorteners (sub-250ms redirect unrolling)
    shortlinks = [u for u in canonical_urls if is_shortener(u)]
    if shortlinks:
        # Resolve shorteners concurrently with strict timeout
        tasks = [resolve_shortlink(u, timeout_seconds=0.25) for u in shortlinks[:2]]
        resolved_results = await asyncio.gather(*tasks, return_exceptions=True)
        for resolved in resolved_results:
            if isinstance(resolved, str) and resolved:
                canonical_dest = canonicalize_url(resolved)
                canonical_urls.append(canonical_dest)
                candidate_keys.extend(generate_threat_lookup_keys(canonical_dest))

    # 4. Fast O(1) Redis Pipeline Check
    threat_match = await check_threat_hashes(redis, candidate_keys, sender=payload.sender)

    if threat_match:
        return AppleMessageFilterResponse(action=FilterAction.FILTER)

    # Also check legacy key format: threat:{hash}
    legacy_keys = [f"threat:{h}" for _, h in candidate_keys if _ == "url"]
    if legacy_keys:
        legacy_matches = await redis.mget(legacy_keys)
        if any(m is not None for m in legacy_matches):
            return AppleMessageFilterResponse(action=FilterAction.FILTER)

    # 5. Non-blocking dispatch to Celery for zero-day analysis
    try:
        celery_app.send_task("analyze_urls_zero_day", args=[canonical_urls])
    except Exception:
        pass

    return AppleMessageFilterResponse(action=FilterAction.NONE)
