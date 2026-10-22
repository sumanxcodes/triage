from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
import logging
from typing import List, Optional
import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


@dataclass
class FeedThreatItem:
    raw_url: str
    threat_type: str = "malware"
    target_brand: Optional[str] = None
    source: str = "generic_feed"
    confidence_score: float = 0.95
    is_online: bool = True
    tags: List[str] = field(default_factory=list)
    added_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class BaseFeedCollector(ABC):
    """
    Abstract Base Class for Ethical Threat Feed Collection.
    Implements rate-limiting, custom User-Agent, safe timeouts, and error handling.
    """

    def __init__(self, timeout_seconds: float = 15.0) -> None:
        self.timeout = timeout_seconds
        self.headers = {
            "User-Agent": settings.THREAT_INTEL_USER_AGENT,
            "Accept": "application/json, text/plain, */*",
            "Accept-Encoding": "gzip, deflate",
        }

    @abstractmethod
    async def fetch_threats(self, limit: Optional[int] = None) -> List[FeedThreatItem]:
        """Fetches and parses threats from the external feed source."""
        pass

    async def _get(self, url: str) -> httpx.Response:
        """Responsible HTTP GET with security timeout and custom user-agent."""
        async with httpx.AsyncClient(
            timeout=self.timeout,
            headers=self.headers,
            follow_redirects=True,
        ) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response
