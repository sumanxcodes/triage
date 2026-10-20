from fastapi import APIRouter, Depends
import redis.asyncio as aioredis

from app.core.redis import get_redis
from app.core.utils import extract_urls, hash_sha256
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
    Strict Privacy Rule: This endpoint is strictly stateless. Do not log `messageBody` or `sender`.
    Performance Requirement: Must respond in under 1 second using Redis cache lookups.
    """
    if not payload.messageBody:
        return AppleMessageFilterResponse(action=FilterAction.NONE)

    # 1. Extract URLs
    urls = extract_urls(payload.messageBody)
    if not urls:
        return AppleMessageFilterResponse(action=FilterAction.NONE)

    # 2. Hash extracted URLs using SHA-256
    hashed_urls = [hash_sha256(url) for url in urls]

    # 3. Check Redis cache in sub-millisecond pipeline lookup
    pipe = redis.pipeline()
    for h in hashed_urls:
        pipe.exists(f"threat:{h}")
    results = await pipe.execute()

    if any(results):
        # Match found: flag as filtered/junk
        return AppleMessageFilterResponse(action=FilterAction.FILTER)

    # 4. Asynchronously send unseen URLs to Celery worker for zero-day analysis
    # Non-blocking dispatch to ensure < 1s latency
    try:
        celery_app.send_task("analyze_urls_zero_day", args=[urls])
    except Exception:
        # Prevent queue connection issues from failing the user's SMS filter request
        pass

    return AppleMessageFilterResponse(action=FilterAction.NONE)
