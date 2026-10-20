from unittest.mock import MagicMock, patch
import pytest
from httpx import ASGITransport, AsyncClient

from app.core.redis import get_redis
from app.core.threat_cache import seed_threat_database
from app.main import app
from worker.analyzer import PhishingAnalysisResult, evaluate_heuristics
from worker.scraper import ScrapedPageData
from worker.tasks import analyze_urls_zero_day


def test_heuristic_analyzer_catches_credential_harvesting_on_untrusted_tld():
    data = ScrapedPageData(
        url="https://auspost-track-verify.xyz/update",
        final_url="https://auspost-track-verify.xyz/update",
        title="Verify Delivery Address - AusPost",
        has_password_input=True,
        has_credit_card_input=False,
        form_actions=["https://auspost-track-verify.xyz/submit"],
        text_snippet="Your parcel AU-9918 is waiting. Please enter your credentials to confirm delivery.",
    )
    result = evaluate_heuristics(data)
    assert result.is_phishing is True
    assert result.target_brand == "Australia Post"
    assert result.confidence_score >= 0.7


def test_heuristic_analyzer_catches_apple_brand_impersonation():
    data = ScrapedPageData(
        url="https://xn--pple-43d.com/login",
        final_url="https://аpple.com/login",
        title="Sign In to Apple ID",
        has_password_input=True,
        has_sensitive_inputs=True,
        form_actions=["https://remote-stealer.xyz/harvest"],
    )
    result = evaluate_heuristics(data)
    assert result.is_phishing is True
    assert result.target_brand == "Apple"


def test_heuristic_analyzer_cleans_legitimate_site():
    data = ScrapedPageData(
        url="https://apple.com/iphone",
        final_url="https://apple.com/iphone",
        title="iPhone 16 Pro - Apple",
        has_password_input=False,
        has_credit_card_input=False,
        text_snippet="Meet iPhone 16 Pro. Built for Apple Intelligence.",
    )
    result = evaluate_heuristics(data)
    assert result.is_phishing is False
    assert result.confidence_score < 0.2


def test_analyze_urls_zero_day_publishes_to_redis():
    mock_scraped = ScrapedPageData(
        url="https://cba-netbank-auth.xyz/login",
        final_url="https://cba-netbank-auth.xyz/login",
        title="CommBank NetBank Login",
        has_password_input=True,
        text_snippet="Log on to NetBank",
    )
    mock_verdict = PhishingAnalysisResult(
        is_phishing=True,
        target_brand="Commonwealth Bank",
        threat_category="credential_harvesting",
        confidence_score=0.95,
        reasons=["Password field on unauthorized .xyz domain"],
    )

    mock_redis = MagicMock()
    mock_pipe = MagicMock()
    mock_redis.pipeline.return_value = mock_pipe

    with patch("worker.tasks.scrape_url_headless", return_value=mock_scraped), \
         patch("worker.tasks.evaluate_with_gemini", return_value=mock_verdict), \
         patch("worker.tasks.get_sync_redis", return_value=mock_redis):
        results = analyze_urls_zero_day.run(["https://cba-netbank-auth.xyz/login"])

    assert "https://cba-netbank-auth.xyz/login" in results
    assert results["https://cba-netbank-auth.xyz/login"]["is_phishing"] is True
    # Verify Redis pipeline called to publish threat
    assert mock_pipe.set.called
    assert mock_pipe.execute.called


@pytest.mark.asyncio
async def test_safari_scan_known_threat(in_memory_redis):
    mock_threats = [
        {
            "url": "https://auspost-track-verify.xyz/update",
            "domain": "auspost-track-verify.xyz",
            "threat_type": "phishing",
            "target_brand": "Australia Post",
        }
    ]
    await seed_threat_database(in_memory_redis, mock_threats)
    app.dependency_overrides[get_redis] = lambda: in_memory_redis

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post(
            "/api/v1/safari/scan",
            json={"url": "https://auspost-track-verify.xyz/update"},
        )

    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "malicious"
    assert data["target_brand"] == "Australia Post"

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_safari_scan_unknown_url_queues_task(in_memory_redis):
    app.dependency_overrides[get_redis] = lambda: in_memory_redis

    mock_task = MagicMock()
    mock_task.id = "mock-task-uuid-1234"

    with patch("app.api.v1.safari.celery_app.send_task", return_value=mock_task):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/safari/scan",
                json={"url": "https://unknown-zero-day-site.com/check"},
            )

    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "pending_analysis"
    assert data["task_id"] == "mock-task-uuid-1234"

    app.dependency_overrides.clear()
