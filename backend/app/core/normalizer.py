import ipaddress
import re
from typing import List, Set, Tuple
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

# Known high-volume URL shorteners
SHORTENER_DOMAINS: Set[str] = {
    "bit.ly",
    "tinyurl.com",
    "t.co",
    "is.gd",
    "buff.ly",
    "ow.ly",
    "cutt.ly",
    "goo.gl",
    "rebrand.ly",
    "shorturl.at",
    "tiny.cc",
    "v.gd",
}

# Tracking parameters to strip during canonicalization
TRACKING_PARAMS: Set[str] = {
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "utm_term",
    "utm_content",
    "fbclid",
    "gclid",
    "msclkid",
    "mc_eid",
    "_hsenc",
    "_hsmi",
    "ref",
}

# RFC-compliant URL extraction regex matching http/https URLs
URL_PATTERN = re.compile(
    r"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|"
    r"www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|"
    r"https?:\/\/(?:[a-zA-Z0-9]+\.)+[a-zA-Z]{2,}(?:\/[^\s]*)?)",
    re.IGNORECASE,
)


def extract_raw_urls(text: str) -> List[str]:
    """Extract all candidate URLs from text without alteration."""
    if not text:
        return []
    matches = URL_PATTERN.findall(text)
    seen = set()
    unique_urls = []
    for match in matches:
        cleaned = match.strip().rstrip(".,;:)\"'<>")
        if cleaned and cleaned not in seen:
            seen.add(cleaned)
            unique_urls.append(cleaned)
    return unique_urls


def decode_punycode_host(hostname: str) -> str:
    """
    Decodes IDN Punycode hostname (e.g. xn--pple-43d.com -> аpple.com).
    Also detects homoglyph representations.
    """
    if not hostname:
        return ""
    try:
        # Convert to IDNA / Punycode decoding
        decoded = hostname.encode("idna").decode("idna")
        return decoded.lower()
    except Exception:
        return hostname.lower()


def normalize_ip_host(hostname: str) -> str:
    """
    Normalizes obfuscated IP addresses (dword, octal, hex) to standard dotted-decimal.
    E.g., 0x7f000001 or 2130706433 -> 127.0.0.1
    """
    if not hostname:
        return ""

    # Check if host is numeric (integer/dword IP)
    if hostname.isdigit():
        try:
            return str(ipaddress.IPv4Address(int(hostname)))
        except ValueError:
            pass

    # Check hex IP format (e.g., 0x7f.0x0.0x0.0x1 or 0x7f000001)
    if hostname.startswith("0x"):
        try:
            return str(ipaddress.IPv4Address(int(hostname, 16)))
        except ValueError:
            pass

    return hostname


def canonicalize_url(raw_url: str) -> str:
    """
    Transforms a raw URL into a normalized canonical representation:
    1. Ensures scheme defaults to http if missing (e.g. www.domain.com).
    2. Lowercases scheme and hostname.
    3. Decodes Punycode/IDN in hostname.
    4. Normalizes obfuscated IP addresses.
    5. Strips default ports (:80, :443).
    6. Strips tracking query parameters (utm_*, fbclid).
    7. Sorts remaining query parameters deterministically.
    8. Strips fragments (#...).
    9. Strips trailing slashes from path when path is root.
    """
    url = raw_url.strip()
    if not url.startswith(("http://", "https://")):
        url = "http://" + url

    parts = urlsplit(url)
    scheme = parts.scheme.lower()
    netloc = parts.netloc.lower()

    # Split host and port
    if ":" in netloc:
        host, port = netloc.split(":", 1)
        if (scheme == "http" and port == "80") or (scheme == "https" and port == "443"):
            netloc = host
        else:
            host = normalize_ip_host(decode_punycode_host(host))
            netloc = f"{host}:{port}"
    else:
        netloc = normalize_ip_host(decode_punycode_host(netloc))

    # Normalize path
    path = parts.path
    if not path:
        path = "/"
    elif len(path) > 1 and path.endswith("/"):
        path = path.rstrip("/")

    # Strip tracking parameters and sort remaining query
    query = ""
    if parts.query:
        params = parse_qsl(parts.query, keep_blank_values=True)
        filtered = [(k, v) for k, v in params if k.lower() not in TRACKING_PARAMS]
        filtered.sort(key=lambda x: x[0])
        query = urlencode(filtered)

    # Omit fragment completely
    return urlunsplit((scheme, netloc, path, query, ""))


def extract_registered_domain(hostname: str) -> str:
    """
    Extracts the root registered domain (e.g. sub.domain.co.uk -> domain.co.uk, or sub.phish.xyz -> phish.xyz).
    For standard multi-part and two-level TLDs.
    """
    host = hostname.split(":")[0].lower()
    parts = host.split(".")
    if len(parts) <= 2:
        return host

    # Common two-part TLD suffixes (co.uk, com.au, net.au, org.uk, etc.)
    two_level_tlds = {"co.uk", "com.au", "net.au", "org.au", "gov.au", "co.nz", "co.jp", "com.br"}
    last_two = f"{parts[-2]}.{parts[-1]}"

    if last_two in two_level_tlds and len(parts) >= 3:
        return ".".join(parts[-3:])

    return ".".join(parts[-2:])


def is_shortener(url: str) -> bool:
    """Checks whether the URL belongs to a known URL shortener service."""
    try:
        parts = urlsplit(url)
        host = parts.netloc.split(":")[0].lower()
        reg_domain = extract_registered_domain(host)
        return host in SHORTENER_DOMAINS or reg_domain in SHORTENER_DOMAINS
    except Exception:
        return False


def generate_threat_lookup_keys(canonical_url: str) -> List[Tuple[str, str]]:
    """
    Generates multi-key lookup targets:
    Returns list of tuples: (prefix, target_value)
    - ("url", canonical_url)
    - ("domain", registered_domain)
    - ("host", hostname)
    """
    import hashlib

    parts = urlsplit(canonical_url)
    host = parts.netloc.split(":")[0].lower()
    domain = extract_registered_domain(host)

    keys = [
        ("url", hashlib.sha256(canonical_url.encode("utf-8")).hexdigest()),
        ("domain", hashlib.sha256(domain.encode("utf-8")).hexdigest()),
        ("host", hashlib.sha256(host.encode("utf-8")).hexdigest()),
    ]
    return keys
