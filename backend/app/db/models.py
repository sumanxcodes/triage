from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import DateTime, Float, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column
from app.db.session import Base


class ThreatRecordModel(Base):
    """
    Master Threat Record stored in PostgreSQL.
    Synchronized down to iOS clients via the /api/v1/threats/delta endpoint.
    """
    __tablename__ = "threat_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    url_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    domain_hash: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    canonical_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    threat_type: Mapped[str] = mapped_column(String(64), nullable=False, default="phishing")
    target_brand: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    confidence_score: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    is_active: Mapped[bool] = mapped_column(nullable=False, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        index=True,
    )

    __table_args__ = (
        Index("idx_threat_active_updated", "is_active", "updated_at"),
    )
