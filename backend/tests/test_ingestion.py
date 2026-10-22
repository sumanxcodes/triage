from unittest.mock import AsyncMock, patch
import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.normalizer import extract_registered_domain
from app.core.whitelist import (
    can_block_domain,
    is_candidate_url_safe_to_ingest,
    is_private_or_invalid_host,
    is_tier1_immune,
    is_tier2_multitenant,
)
from app.db.session import Base
from worker.feeds.base import FeedThreatItem
from worker.feeds.openphish import OpenPhishCollector
from worker.feeds.urlhaus import URLhausCollector
from worker.ingestion import ingest_threat_items


# --- Test 1: Whitelist & Safety Guards ---

def test_whitelist_private_and_loopback_ips():
    assert is_private_or_invalid_host("127.0.0.1") is True
    assert is_private_or_invalid_host("localhost") is True
    assert is_private_or_invalid_host("192.168.1.1") is True
    assert is_private_or_invalid_host("10.0.0.1") is True
    assert is_private_or_invalid_host("172.16.0.1") is True
    assert is_private_or_invalid_host("0.0.0.0") is True
    assert is_private_or_invalid_host("example.com") is False
    assert is_private_or_invalid_host("bad-actor.xyz") is False


def test_whitelist_tier1_immunity():
    # Banking
    assert is_tier1_immune("commbank.com.au") is True
    assert is_tier1_immune("netbank.commbank.com.au") is True
    assert is_tier1_immune("cba.com.au") is True
    assert is_tier1_immune("anz.com") is True
    assert is_tier1_immune("westpac.com.au") is True

    # Tech & Infrastructure
    assert is_tier1_immune("apple.com") is True
    assert is_tier1_immune("idmsa.apple.com") is True
    assert is_tier1_immune("google.com") is True
    assert is_tier1_immune("cloudflare.com") is True

    # Government / Edu
    assert is_tier1_immune("police.vic.gov.au") is True
    assert is_tier1_immune("my.gov.au") is True
    assert is_tier1_immune("unimelb.edu.au") is True

    # Phishing / Malicious
    assert is_tier1_immune("cba-netbank-auth.com") is False
    assert is_tier1_immune("auspost-tracking-parcel.top") is False
    assert is_tier1_immune("apple-id-verify.xyz") is False


def test_whitelist_tier2_multitenant_scope_isolation():
    # Multi-tenant cloud hosting should be identified for path-only blocking
    assert is_tier2_multitenant("pages.dev") is True
    assert is_tier2_multitenant("subdomain.pages.dev") is True
    assert is_tier2_multitenant("workers.dev") is True
    assert is_tier2_multitenant("docs.google.com") is True
    assert is_tier2_multitenant("storage.googleapis.com") is True
    assert is_tier2_multitenant("firebaseapp.com") is True

    # Cannot block domain at root level for tier 2
    assert can_block_domain("pages.dev") is False
    assert can_block_domain("workers.dev") is False

    # Dedicated phishing domain CAN be blocked at root level
    assert can_block_domain("auspost-scam.xyz") is True
    assert can_block_domain("evil-phish.top") is True


def test_is_candidate_url_safe_to_ingest():
    # Dangerous / Whitelisted should be rejected
    assert is_candidate_url_safe_to_ingest("http://127.0.0.1:8000/evil") is False
    assert is_candidate_url_safe_to_ingest("https://localhost/test") is False
    assert is_candidate_url_safe_to_ingest("https://www.commbank.com.au/login") is False
    assert is_candidate_url_safe_to_ingest("https://apple.com/au") is False
    assert is_candidate_url_safe_to_ingest("https://my.gov.au") is False

    # Safe to ingest
    assert is_candidate_url_safe_to_ingest("https://cba-netbank-auth.com/login") is True
    assert is_candidate_url_safe_to_ingest("https://auspost-track.top/parcel") is True
    assert is_candidate_url_safe_to_ingest("http://phish.workers.dev/evil-form") is True


# --- Test 2: Two-Level TLD Normalization ---

def test_two_level_tld_extraction():
    assert extract_registered_domain("fake-cba.com.au") == "fake-cba.com.au"
    assert extract_registered_domain("sub.fake-cba.com.au") == "fake-cba.com.au"
    assert extract_registered_domain("login.stage.bank.co.uk") == "bank.co.uk"
    assert extract_registered_domain("phish.org.au") == "phish.org.au"
    assert extract_registered_domain("evil.xyz") == "evil.xyz"
    assert extract_registered_domain("sub.evil.xyz") == "evil.xyz"


# --- Test 3: Feed Collectors ---

@pytest.mark.asyncio
async def test_urlhaus_collector_mock():
    mock_json = {
        "query_status": "ok",
        "urls": [
            {
                "url": "http://malware-drop.top/loader.exe",
                "url_status": "online",
                "threat": "malware_download",
                "tags": ["RedLineStealer", "exe"],
                "dateadded": "2026-10-22 01:00:00 UTC",
            },
            {
                "url": "http://old-dead-host.xyz/payload.bin",
                "url_status": "offline",
                "threat": "malware_download",
                "tags": ["Mozi"],
                "dateadded": "2026-10-20 01:00:00 UTC",
            },
        ],
    }

    mock_resp = httpx.Response(status_code=200, json=mock_json, request=httpx.Request("GET", "http://test"))

    with patch.object(URLhausCollector, "_get", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_resp
        collector = URLhausCollector(auth_key="test_key")
        items = await collector.fetch_threats(limit=10)

    assert len(items) == 2
    assert items[0].raw_url == "http://malware-drop.top/loader.exe"
    assert items[0].is_online is True
    assert items[0].target_brand == "RedLineStealer"
    assert items[1].raw_url == "http://old-dead-host.xyz/payload.bin"
    assert items[1].is_online is False


@pytest.mark.asyncio
async def test_openphish_collector_mock():
    mock_text = """# OpenPhish Feed
http://fake-apple-auth.top/signin
https://cba-security-check.xyz/netbank
http://compromised-site.com/wp-login
"""
    mock_resp = httpx.Response(status_code=200, text=mock_text, request=httpx.Request("GET", "http://test"))

    with patch.object(OpenPhishCollector, "_get", new_callable=AsyncMock) as mock_get:
        mock_get.return_value = mock_resp
        collector = OpenPhishCollector()
        items = await collector.fetch_threats(limit=10)

    assert len(items) == 3
    assert items[0].raw_url == "http://fake-apple-auth.top/signin"
    assert items[0].threat_type == "phishing"
    assert items[0].source == "openphish"


# --- Test 4: Database Ingestion & Pruning ---

@pytest.fixture
async def ingestion_db_session():
    test_engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    async_session = async_sessionmaker(bind=test_engine, class_=AsyncSession, expire_on_commit=False)

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as session:
        yield session

    await test_engine.dispose()


@pytest.mark.asyncio
async def test_ingest_threat_items_upsert_and_whitelist(ingestion_db_session):
    items = [
        # Legitimate whitelisted URL - must be skipped!
        FeedThreatItem(raw_url="https://www.commbank.com.au/personal.html"),
        # Multi-tenant cloud URL - url_hash stored, but domain_hash equals url_hash (not root domain)!
        FeedThreatItem(raw_url="https://phish.workers.dev/login", target_brand="WorkersPhish"),
        # Standard dedicated phishing domain
        FeedThreatItem(raw_url="https://cba-netbank-fake.top/login", target_brand="Commonwealth Bank"),
    ]

    stats = await ingest_threat_items(items, session=ingestion_db_session)

    assert stats["received"] == 3
    assert stats["skipped_whitelist"] == 1
    assert stats["inserted"] == 2
    assert stats["updated"] == 0

    # Verify duplicate item updates instead of raising IntegrityError
    dup_items = [
        FeedThreatItem(raw_url="https://cba-netbank-fake.top/login", is_online=False)
    ]
    update_stats = await ingest_threat_items(dup_items, session=ingestion_db_session)
    assert update_stats["updated"] == 1
    assert update_stats["inserted"] == 0
