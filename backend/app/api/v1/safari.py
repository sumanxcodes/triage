import json
from celery.result import AsyncResult
from fastapi import APIRouter, Depends, status
import redis.asyncio as aioredis

from app.core.normalizer import canonicalize_url, generate_threat_lookup_keys
from app.core.redis import get_redis
from app.core.threat_cache import check_threat_hashes
from app.schemas.threat import SafariScanRequest, SafariScanResponse, SafariTaskStatusResponse
from worker.celery_app import celery_app

router = APIRouter(prefix="/safari", tags=["Safari Extension"])


@router.post("/scan", response_model=SafariScanResponse, status_code=status.HTTP_200_OK)
async def scan_safari_url(
    payload: SafariScanRequest,
    redis: aioredis.Redis = Depends(get_redis),
) -> SafariScanResponse:
    """
    Endpoint invoked by iOS Safari Web Extension when a user navigates to an unknown link.
    1. Canonicalizes URL and checks Redis for existing threat or analysis cache.
    2. If malicious, returns blocked verdict immediately.
    3. If unknown, queues Playwright + Gemini analysis task in Celery worker and returns task_id.
    """
    canonical = canonicalize_url(payload.url)
    keys = generate_threat_lookup_keys(canonical)

    # 1. Check Redis threat cache (O(1) MGET)
    threat_match = await check_threat_hashes(redis, keys)
    if threat_match:
        return SafariScanResponse(
            url=canonical,
            status="malicious",
            threat_type=threat_match.get("threat_type", "phishing"),
            target_brand=threat_match.get("target_brand", "Unknown"),
            confidence_score=threat_match.get("confidence_score", 1.0),
            reasons=threat_match.get("reasons", ["Known threat listed in global cache"]),
        )

    # 2. Check cached zero-day analysis verdicts
    url_hash = keys[0][1]
    cached_analysis = await redis.get(f"analysis:url:{url_hash}")
    if cached_analysis:
        try:
            analysis_data = json.loads(cached_analysis)
            return SafariScanResponse(
                url=canonical,
                status="malicious" if analysis_data.get("is_phishing") else "safe",
                threat_type=analysis_data.get("threat_category"),
                target_brand=analysis_data.get("target_brand"),
                confidence_score=analysis_data.get("confidence_score"),
                reasons=analysis_data.get("reasons", []),
            )
        except Exception:
            pass

    # 3. Dispatch to Celery worker for zero-day DOM scraping & AI evaluation
    task_id: str | None = None
    try:
        task = celery_app.send_task("analyze_urls_zero_day", args=[[canonical]])
        task_id = task.id
    except Exception:
        pass

    return SafariScanResponse(
        url=canonical,
        status="pending_analysis",
        task_id=task_id,
        confidence_score=None,
    )


@router.get("/status/{task_id}", response_model=SafariTaskStatusResponse)
async def get_safari_task_status(task_id: str) -> SafariTaskStatusResponse:
    """
    Poll status of a background zero-day AI analysis task.
    Allows iOS Safari Web Extension interstitial to update dynamically when complete.
    """
    res = AsyncResult(task_id, app=celery_app)
    result_data = None
    if res.ready():
        result_data = res.result if isinstance(res.result, dict) else {"status": str(res.result)}

    return SafariTaskStatusResponse(
        task_id=task_id,
        status=res.status,
        result=result_data,
    )
