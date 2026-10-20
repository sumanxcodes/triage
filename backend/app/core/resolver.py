import asyncio
from typing import Optional
import httpx
from app.core.normalizer import is_shortener


async def resolve_shortlink(
    url: str,
    timeout_seconds: float = 0.25,
    client: Optional[httpx.AsyncClient] = None,
) -> Optional[str]:
    """
    Sub-second HTTP HEAD resolver for URL shorteners (bit.ly, t.co, etc.).
    Extracts the unrolled destination URL via the 'Location' header
    without downloading the response body.
    """
    if not is_shortener(url):
        return None

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        )
    }

    try:
        # Use passed client or create dedicated client with strict connect/read timeout
        if client:
            resp = await client.head(
                url,
                headers=headers,
                follow_redirects=False,
                timeout=timeout_seconds,
            )
            if resp.is_redirect and "location" in resp.headers:
                return resp.headers["location"]
        else:
            async with httpx.AsyncClient(timeout=timeout_seconds) as session:
                resp = await session.head(
                    url,
                    headers=headers,
                    follow_redirects=False,
                )
                if resp.is_redirect and "location" in resp.headers:
                    return resp.headers["location"]
    except (httpx.TimeoutException, httpx.RequestError, asyncio.TimeoutError):
        # Strict latency guarantee: timeout must not raise an error
        return None

    return None
