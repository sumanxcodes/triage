import json
import time
from pathlib import Path
import pytest
from httpx import ASGITransport, AsyncClient

from app.core.redis import get_redis
from app.main import app


@pytest.mark.asyncio
async def test_health_check(async_client):
    response = await async_client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "environment": "development"}


@pytest.mark.asyncio
async def test_sms_filter_with_known_threat(mock_redis_with_threat):
    app.dependency_overrides[get_redis] = lambda: mock_redis_with_threat

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        start = time.perf_counter()
        response = await client.post(
            "/api/v1/sms/filter",
            json={
                "sender": "+61412345678",
                "messageBody": "Click here to verify parcel: https://auspost-track-verify.xyz/update",
            },
        )
        duration = time.perf_counter() - start

    assert response.status_code == 200
    assert response.json()["action"] == "filter"
    # Strict Apple constraint: Response must be < 1.0 second
    assert duration < 1.0

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_sms_filter_with_clean_message(mock_redis_clean):
    app.dependency_overrides[get_redis] = lambda: mock_redis_clean

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/sms/filter",
            json={
                "sender": "+61499999999",
                "messageBody": "Your 2FA authentication code is 123456.",
            },
        )

    assert response.status_code == 200
    assert response.json()["action"] == "none"

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_shared_mock_payloads(mock_redis_with_threat, mock_redis_clean):
    shared_path = Path(__file__).resolve().parent.parent.parent / "shared" / "mock_sms_payloads.json"
    assert shared_path.exists(), f"Shared payloads not found at {shared_path}"

    with open(shared_path, "r") as f:
        payloads = json.load(f)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        for item in payloads:
            # Override redis based on expected action
            if item["expected_action"] == "filter":
                app.dependency_overrides[get_redis] = lambda: mock_redis_with_threat
            else:
                app.dependency_overrides[get_redis] = lambda: mock_redis_clean

            response = await client.post(
                "/api/v1/sms/filter",
                json={
                    "sender": item["sender"],
                    "messageBody": item["messageBody"],
                },
            )
            assert response.status_code == 200
            assert response.json()["action"] == item["expected_action"]

    app.dependency_overrides.clear()
