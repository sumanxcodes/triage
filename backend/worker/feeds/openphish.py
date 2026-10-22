from datetime import datetime, timezone
import logging
from typing import List, Optional

from app.core.config import settings
from worker.feeds.base import BaseFeedCollector, FeedThreatItem

logger = logging.getLogger(__name__)


class OpenPhishCollector(BaseFeedCollector):
    """
    Ethical Collector for OpenPhish Community Feed.
    Pulls verified active credential-harvesting phishing URLs.
    """

    def __init__(self, feed_url: Optional[str] = None, timeout_seconds: float = 20.0) -> None:
        super().__init__(timeout_seconds=timeout_seconds)
        self.feed_url = feed_url or settings.OPENPHISH_FEED_URL

    async def fetch_threats(self, limit: Optional[int] = None) -> List[FeedThreatItem]:
        logger.info(f"Fetching OpenPhish community feed from {self.feed_url}")
        items: List[FeedThreatItem] = []

        try:
            response = await self._get(self.feed_url)
            lines = response.text.splitlines()

            now = datetime.now(timezone.utc)
            for line in lines:
                raw_url = line.strip()
                if not raw_url or raw_url.startswith("#"):
                    continue

                items.append(
                    FeedThreatItem(
                        raw_url=raw_url,
                        threat_type="phishing",
                        target_brand=None,
                        source="openphish",
                        confidence_score=0.90,
                        is_online=True,
                        tags=["phishing", "openphish"],
                        added_at=now,
                    )
                )

                if limit and len(items) >= limit:
                    break

            logger.info(f"Successfully parsed {len(items)} phishing URLs from OpenPhish.")
            return items

        except Exception as e:
            logger.error(f"Failed to fetch or parse OpenPhish feed: {e}")
            return []
