import ipaddress
from typing import Set
from urllib.parse import urlsplit

from app.core.normalizer import extract_registered_domain

# Tier 1: Absolute Immunity Whitelist (Root domains that can NEVER be blocked under any circumstances)
TIER1_IMMUNE_DOMAINS: Set[str] = {
    # Major Global Tech & Infrastructure
    "google.com",
    "apple.com",
    "microsoft.com",
    "amazon.com",
    "meta.com",
    "facebook.com",
    "whatsapp.com",
    "cloudflare.com",
    "github.com",
    "twitter.com",
    "x.com",
    "linkedin.com",
    "yahoo.com",
    "live.com",
    "office.com",
    "outlook.com",
    "icloud.com",
    # Australian Banking & Financial Institutions
    "commbank.com.au",
    "cba.com.au",
    "westpac.com.au",
    "anz.com",
    "anz.com.au",
    "nab.com.au",
    "macquarie.com.au",
    "bendigobank.com.au",
    "bankofmelbourne.com.au",
    "stgeorge.com.au",
    "suncorp.com.au",
    "bankwest.com.au",
    "paypal.com",
    "stripe.com",
    "square.com",
    # Australian Telco & Infrastructure
    "telstra.com.au",
    "optus.com.au",
    "vodafone.com.au",
    "tpg.com.au",
    "iinet.net.au",
    "aussiebroadband.com.au",
    # Logistics & Courier
    "auspost.com.au",
    "startrack.com.au",
    "dhl.com",
    "fedex.com",
    "ups.com",
    # Toll & Road Services (Common Smishing Target Brands)
    "linkt.com.au",
    "eastlink.com.au",
    "transurban.com",
}

# Tier 2: Multi-Tenant & Free Cloud Hosting (Path-Only Blocking Allowed; Domain-Level Blocking PROHIBITED)
TIER2_MULTITENANT_DOMAINS: Set[str] = {
    # Serverless / Static web hosts
    "pages.dev",
    "workers.dev",
    "web.app",
    "firebaseapp.com",
    "vercel.app",
    "netlify.app",
    "github.io",
    "gitlab.io",
    "glitch.me",
    "render.com",
    "railway.app",
    "fly.dev",
    # Cloud Object Storage & File Sharing
    "s3.amazonaws.com",
    "blob.core.windows.net",
    "storage.googleapis.com",
    "drive.google.com",
    "docs.google.com",
    "forms.office.com",
    "onedrive.live.com",
    "dropbox.com",
    "sharepoint.com",
    "ipfs.io",
    "dweb.link",
    "cloudflare-ipfs.com",
    # Tunneling services
    "ngrok.io",
    "ngrok-free.app",
    "localtunnel.me",
    "pagekite.me",
}

# Suffixes with automatic immunity
IMMUNE_TLD_SUFFIXES = (
    ".gov.au",
    ".gov",
    ".mil",
    ".edu.au",
    ".edu",
)


def is_private_or_invalid_host(host: str) -> bool:
    """
    Checks if a host is localhost, invalid, or belongs to RFC 1918 private / loopback IP spaces.
    Prevents SSRF and internal network blocking.
    """
    clean_host = host.split(":")[0].strip().lower()
    if clean_host in {"localhost", "127.0.0.1", "::1", "0.0.0.0"}:
        return True

    try:
        ip = ipaddress.ip_address(clean_host)
        return ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_multicast or ip.is_unspecified
    except ValueError:
        return False


def is_tier1_immune(host_or_domain: str) -> bool:
    """
    Returns True if domain or host is protected by Tier 1 immunity (cannot be ingested or blocked).
    """
    clean = host_or_domain.split(":")[0].strip().lower()
    reg_domain = extract_registered_domain(clean)

    if reg_domain in TIER1_IMMUNE_DOMAINS or clean in TIER1_IMMUNE_DOMAINS:
        return True

    for suffix in IMMUNE_TLD_SUFFIXES:
        if clean.endswith(suffix):
            return True

    return False


def is_tier2_multitenant(host_or_domain: str) -> bool:
    """
    Returns True if host/domain belongs to a shared cloud hosting / SaaS platform.
    When True, exact URL blocking (url_hash) is allowed, but domain-wide blocking (domain_hash) is prohibited.
    """
    clean = host_or_domain.split(":")[0].strip().lower()
    reg_domain = extract_registered_domain(clean)

    return clean in TIER2_MULTITENANT_DOMAINS or reg_domain in TIER2_MULTITENANT_DOMAINS


def can_block_domain(host_or_domain: str) -> bool:
    """
    Determines whether a domain can be blocked at the root domain level.
    Returns False for immune services and multi-tenant hosts.
    """
    if is_private_or_invalid_host(host_or_domain):
        return False
    if is_tier1_immune(host_or_domain):
        return False
    if is_tier2_multitenant(host_or_domain):
        return False
    return True


def is_candidate_url_safe_to_ingest(raw_or_canonical_url: str) -> bool:
    """
    Validates whether an incoming URL from a threat feed is safe to ingest.
    Rejects private IPs, loopback, and Tier 1 immune domains.
    """
    try:
        parts = urlsplit(raw_or_canonical_url)
        host = parts.netloc.split(":")[0].strip().lower()
        if not host:
            return False
        if is_private_or_invalid_host(host):
            return False
        if is_tier1_immune(host):
            return False
        return True
    except Exception:
        return False
