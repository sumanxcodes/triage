from datetime import datetime
from typing import List, Optional
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
    threat_type: Optional[str] = None
    confidence_score: Optional[float] = None
