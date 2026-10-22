from datetime import datetime, timezone
import logging
from typing import List, Optional

from app.core.config import settings
from worker.feeds.base import BaseFeedCollector, FeedThreatItem

logger = logging.getLogger(__name__)


class URLhausCollector(BaseFeedCollector):
    """
    Ethical Collector for URLhaus by abuse.ch (Bern University of Applied Sciences).
    Pulls recent malware distribution and payload delivery links.
    """

    def __init__(self, feed_url: Optional[str] = None, timeout_seconds: float = 20.0) -> None:
        super().__init__(timeout_seconds=timeout_seconds)
        self.feed_url = feed_url or settings.URLHAUS_RECENT_URL

    async def fetch_threats(self, limit: Optional[int] = None) -> List[FeedThreatItem]:
        logger.info(f"Fetching URLhaus feed from {self.feed_url}")
        items: List[FeedThreatItem] = []

        try:
            response = await self._get(self.feed_url)
            data = response.json()

            if data.get("query_status") != "ok":
                logger.warning(f"URLhaus returned non-ok query_status: {data.get('query_status')}")
                return []

            raw_urls = data.get("urls", [])
            for entry in raw_urls:
                raw_url = entry.get("url")
                if not raw_url:
                    continue

                url_status = entry.get("url_status", "online")
                is_online = (url_status == "online")

                # Tags (e.g. RedLineStealer, Mozi, Emotet)
                tags = entry.get("tags") or []
                threat_tag = tags[0] if tags else None

                # Threat type classification
                threat_category = entry.get("threat") or "malware_download"

                # Parse dateadded
                date_added = None
                date_str = entry.get("dateadded")
                if date_str:
                    try:
                        # Format: "2026-10-22 01:23:45 UTC"
                        cleaned_date = date_str.replace(" UTC", "")
                        date_added = datetime.strptime(cleaned_date, "%Y-%m-%d %H:%M:%S").replace(
                            tzinfo=timezone.utc
                        )
                    except Exception:
                        date_added = datetime.now(timezone.utc)

                items.append(
                    FeedThreatItem(
                        raw_url=raw_url,
                        threat_type=threat_category,
                        target_brand=threat_tag,
                        source="urlhaus",
                        confidence_score=0.95 if is_online else 0.5,
                        is_online=is_online,
                        tags=tags,
                        added_at=date_added or datetime.now(timezone.utc),
                    )
                )

                if limit and len(items) >= limit:
                    break

            logger.info(f"Successfully parsed {len(items)} threat URLs from URLhaus.")
            return items

        except Exception as e:
            logger.error(f"Failed to fetch or parse URLhaus feed: {e}")
            return []
