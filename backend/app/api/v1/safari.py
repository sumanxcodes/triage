from fastapi import APIRouter, Depends, status
import redis.asyncio as aioredis

from app.core.redis import get_redis
from app.core.utils import hash_sha256
from app.schemas.threat import SafariScanRequest, SafariScanResponse
from worker.celery_app import celery_app

router = APIRouter(prefix="/safari", tags=["Safari Extension"])


@router.post("/scan", response_model=SafariScanResponse, status_code=status.HTTP_200_OK)
async def scan_safari_url(
    payload: SafariScanRequest,
    redis: aioredis.Redis = Depends(get_redis),
) -> SafariScanResponse:
    """
    Endpoint invoked by iOS Safari Web Extension when a user navigates to an unknown link.
    1. Checks Redis cache for existing threat hash.
    2. If safe/known, returns immediately.
    3. If unknown, dispatches background Playwright + Gemini analysis task.
    """
    url_hash = hash_sha256(payload.url)
    is_threat = await redis.exists(f"threat:{url_hash}")

    if is_threat:
        return SafariScanResponse(
            url=payload.url,
            status="malicious",
            threat_type="phishing",
            confidence_score=1.0,
        )

    # Dispatch to Celery for zero-day DOM scraping & AI evaluation
    try:
        celery_app.send_task("analyze_urls_zero_day", args=[[payload.url]])
    except Exception:
        pass

    return SafariScanResponse(
        url=payload.url,
        status="pending_analysis",
        confidence_score=None,
    )
