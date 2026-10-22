from datetime import datetime, timezone
import logging
from typing import List, Optional

from app.core.config import settings
from worker.feeds.base import BaseFeedCollector, FeedThreatItem

logger = logging.getLogger(__name__)


class PhishingArmyCollector(BaseFeedCollector):
    """
    Ethical Collector for Phishing Army (Extended Blocklist).
    Aggregates high-confidence, low-false-positive active phishing domains without requiring an API key.
    """

    def __init__(self, feed_url: Optional[str] = None, timeout_seconds: float = 20.0) -> None:
        super().__init__(timeout_seconds=timeout_seconds)
        self.feed_url = feed_url or settings.PHISHING_ARMY_FEED_URL

    async def fetch_threats(self, limit: Optional[int] = None) -> List[FeedThreatItem]:
        logger.info(f"Fetching Phishing Army feed from {self.feed_url}")
        items: List[FeedThreatItem] = []

        try:
            response = await self._get(self.feed_url)
            lines = response.text.splitlines()

            now = datetime.now(timezone.utc)
            for line in lines:
                raw_domain = line.strip()
                if not raw_domain or raw_domain.startswith("#"):
                    continue

                # Ensure scheme for URL normalizer
                raw_url = f"http://{raw_domain}"

                items.append(
                    FeedThreatItem(
                        raw_url=raw_url,
                        threat_type="phishing",
                        target_brand=None,
                        source="phishing_army",
                        confidence_score=0.92,
                        is_online=True,
                        tags=["phishing", "phishing_army"],
                        added_at=now,
                    )
                )

                if limit and len(items) >= limit:
                    break

            logger.info(f"Successfully parsed {len(items)} phishing domains from Phishing Army.")
            return items

        except Exception as e:
            logger.error(f"Failed to fetch or parse Phishing Army feed: {e}")
            return []
