import json
from pathlib import Path
import time
from unittest.mock import patch
import pytest
from httpx import ASGITransport, AsyncClient

from app.core.redis import get_redis
from app.core.threat_cache import seed_threat_database
from app.main import app


@pytest.mark.asyncio
async def test_health_check(async_client):
    response = await async_client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "environment": "development"}


@pytest.mark.asyncio
async def test_sms_filter_latency_under_one_second(in_memory_redis):
    # Seed known threat
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
        start = time.perf_counter()
        response = await client.post(
            "/api/v1/sms/filter",
            json={
                "sender": "+61412345678",
                "messageBody": "Verify delivery address now: https://auspost-track-verify.xyz/update",
            },
        )
        duration = time.perf_counter() - start

    assert response.status_code == 200
    assert response.json()["action"] == "filter"
    # Strict Apple constraint: ILNetworkResponse MUST be < 1.0 second
    assert duration < 1.0

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_shared_mock_payloads_end_to_end(in_memory_redis):
    """
    Validates all attack vectors defined in shared/mock_sms_payloads.json
    against threats seeded from shared/mock_threat_urls.json.
    """
    shared_dir = Path(__file__).resolve().parent.parent.parent / "shared"
    threats_file = shared_dir / "mock_threat_urls.json"
    payloads_file = shared_dir / "mock_sms_payloads.json"

    with open(threats_file, "r") as f:
        threats = json.load(f)
    with open(payloads_file, "r") as f:
        payloads = json.load(f)

    # Seed Redis with threat database
    await seed_threat_database(in_memory_redis, threats)
    app.dependency_overrides[get_redis] = lambda: in_memory_redis

    # Mock shortlink resolution for bit.ly
    async def mock_resolve_shortlink(url, timeout_seconds=0.25, client=None):
        if "bit.ly/cba-secure-verify" in url:
            return "https://cba-netbank-auth.com/login"
        return None

    with patch("app.api.v1.sms.resolve_shortlink", side_effect=mock_resolve_shortlink):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            for item in payloads:
                start = time.perf_counter()
                response = await client.post(
                    "/api/v1/sms/filter",
                    json={
                        "sender": item["sender"],
                        "messageBody": item["messageBody"],
                    },
                )
                duration = time.perf_counter() - start

                assert response.status_code == 200, f"Failed on {item['description']}: {response.text}"
                data = response.json()
                assert data["action"] == item["expected_action"], (
                    f"Mismatch on '{item['description']}': "
                    f"expected {item['expected_action']}, got {data['action']}"
                )
                assert duration < 1.0, f"Latency violation on '{item['description']}': {duration}s >= 1.0s"

    app.dependency_overrides.clear()
