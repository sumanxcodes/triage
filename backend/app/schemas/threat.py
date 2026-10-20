from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ThreatHashItem(BaseModel):
    hash: str = Field(description="SHA-256 hash of the malicious URL")
    category: str = Field(default="phishing", description="Threat classification")
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ThreatDeltaResponse(BaseModel):
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    added_hashes: List[ThreatHashItem] = Field(default_factory=list)
    removed_hashes: List[str] = Field(default_factory=list)


class SafariScanRequest(BaseModel):
    url: str = Field(description="Target URL intercepted by Safari extension")


class SafariScanResponse(BaseModel):
    url: str
    status: str = Field(description="'safe', 'malicious', or 'pending_analysis'")
    task_id: Optional[str] = Field(default=None, description="Celery task ID for background analysis")
    threat_type: Optional[str] = None
    target_brand: Optional[str] = None
    confidence_score: Optional[float] = None
    reasons: List[str] = Field(default_factory=list)


class SafariTaskStatusResponse(BaseModel):
    task_id: str
    status: str = Field(description="'PENDING', 'STARTED', 'SUCCESS', or 'FAILURE'")
    result: Optional[Dict[str, Any]] = None
