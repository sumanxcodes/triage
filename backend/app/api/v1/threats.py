from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import ThreatRecordModel
from app.db.session import get_db_session
from app.schemas.threat import ThreatDeltaResponse, ThreatHashItem

router = APIRouter(prefix="/threats", tags=["Threat Intelligence Sync"])


@router.get("/delta", response_model=ThreatDeltaResponse)
async def get_threat_delta(
    since: Optional[datetime] = Query(
        default=None,
        description="ISO 8601 timestamp of client's last synchronization. Omit for full initial seed.",
    ),
    limit: int = Query(default=5000, le=10000, description="Max number of threat hashes to return"),
    session: AsyncSession = Depends(get_db_session),
) -> ThreatDeltaResponse:
    """
    Offline Database Synchronization (Flow A):
    Allows the main iOS application to query newly discovered threat hashes
    and updates to sync to local SQLite (GRDB).
    """
    now_utc = datetime.now(timezone.utc)
    added_hashes: list[ThreatHashItem] = []
    removed_hashes: list[str] = []

    try:
        if since is not None:
            # Incremental Delta Sync: return active threats created/updated since last sync,
            # and revoked threats to remove from local SQLite cache.
            query = (
                select(ThreatRecordModel)
                .where(ThreatRecordModel.updated_at > since)
                .order_by(ThreatRecordModel.updated_at.asc())
                .limit(limit)
            )
            result = await session.execute(query)
            records = result.scalars().all()

            for rec in records:
                if rec.is_active:
                    added_hashes.append(
                        ThreatHashItem(
                            hash=rec.url_hash,
                            domain_hash=rec.domain_hash,
                            category=rec.threat_type,
                            target_brand=rec.target_brand,
                            created_at=rec.created_at,
                        )
                    )
                else:
                    removed_hashes.append(rec.url_hash)
        else:
            # Initial Full Bootstrap: return currently active threats
            query = (
                select(ThreatRecordModel)
                .where(ThreatRecordModel.is_active.is_(True))
                .order_by(ThreatRecordModel.created_at.desc())
                .limit(limit)
            )
            result = await session.execute(query)
            records = result.scalars().all()

            for rec in records:
                added_hashes.append(
                    ThreatHashItem(
                        hash=rec.url_hash,
                        domain_hash=rec.domain_hash,
                        category=rec.threat_type,
                        target_brand=rec.target_brand,
                        created_at=rec.created_at,
                    )
                )

    except Exception:
        # If DB is temporarily unavailable, return empty delta with current timestamp
        pass

    return ThreatDeltaResponse(
        timestamp=now_utc,
        added_hashes=added_hashes,
        removed_hashes=removed_hashes,
    )
