from datetime import datetime, timezone
from fastapi import APIRouter
from app.schemas.threat import ThreatDeltaResponse

router = APIRouter(prefix="/threats", tags=["Threat Intelligence Sync"])


@router.get("/delta", response_model=ThreatDeltaResponse)
async def get_threat_delta(since: str | None = None) -> ThreatDeltaResponse:
    """
    Offline Database Synchronization (Flow A):
    Allows the main iOS application to query newly discovered threat hashes
    added in the last 24 hours to sync to local SQLite (GRDB).
    """
    # Stub response for initial scaffold
    return ThreatDeltaResponse(
        timestamp=datetime.now(timezone.utc),
        added_hashes=[],
        removed_hashes=[],
    )
