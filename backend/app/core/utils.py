import hashlib
import re
from typing import List

# RFC-compliant URL extraction regex matching http/https URLs
URL_PATTERN = re.compile(
    r"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|"
    r"www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|"
    r"https?:\/\/(?:[a-zA-Z0-9]+\.)+[a-zA-Z]{2,}(?:\/[^\s]*)?)",
    re.IGNORECASE,
)


def extract_urls(text: str) -> List[str]:
    """Extract all URLs from a given SMS or message text."""
    if not text:
        return []
    matches = URL_PATTERN.findall(text)
    # Deduplicate while preserving order
    seen = set()
    unique_urls = []
    for match in matches:
        cleaned = match.strip().rstrip(".,;:)")
        if cleaned and cleaned not in seen:
            seen.add(cleaned)
            unique_urls.append(cleaned)
    return unique_urls


def hash_sha256(value: str) -> str:
    """Generate SHA-256 hexadecimal hash for a string."""
    return hashlib.sha256(value.encode("utf-8")).hexdigest()
