from datetime import datetime, timedelta, timezone
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.models import ThreatRecordModel
from app.db.session import Base, get_db_session
from app.main import app


@pytest.fixture
async def test_db_session():
    # Use in-memory SQLite with async driver for fast isolated unit tests
    test_engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    async_session = async_sessionmaker(bind=test_engine, class_=AsyncSession, expire_on_commit=False)

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as session:
        yield session

    await test_engine.dispose()


@pytest.mark.asyncio
async def test_threats_delta_full_bootstrap(test_db_session):
    # Seed 2 active threats
    now = datetime.now(timezone.utc)
    threat1 = ThreatRecordModel(
        url_hash="hash111",
        domain_hash="domhash111",
        canonical_url="https://scam1.xyz/login",
        threat_type="phishing",
        target_brand="Apple",
        is_active=True,
        created_at=now - timedelta(days=2),
        updated_at=now - timedelta(days=2),
    )
    threat2 = ThreatRecordModel(
        url_hash="hash222",
        domain_hash="domhash222",
        canonical_url="https://scam2.xyz/track",
        threat_type="phishing",
        target_brand="AusPost",
        is_active=True,
        created_at=now - timedelta(hours=5),
        updated_at=now - timedelta(hours=5),
    )
    test_db_session.add_all([threat1, threat2])
    await test_db_session.commit()

    app.dependency_overrides[get_db_session] = lambda: test_db_session

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/api/v1/threats/delta")

    assert resp.status_code == 200
    data = resp.json()
    assert len(data["added_hashes"]) == 2
    assert len(data["removed_hashes"]) == 0
    hashes = [h["hash"] for h in data["added_hashes"]]
    assert "hash111" in hashes
    assert "hash222" in hashes

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_threats_delta_incremental_sync(test_db_session):
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(hours=2)

    # 1 older threat
    threat_old = ThreatRecordModel(
        url_hash="hash_old",
        domain_hash="dom_old",
        canonical_url="https://old.xyz",
        is_active=True,
        created_at=now - timedelta(days=5),
        updated_at=now - timedelta(days=5),
    )
    # 1 new active threat
    threat_new = ThreatRecordModel(
        url_hash="hash_new",
        domain_hash="dom_new",
        canonical_url="https://new.xyz",
        is_active=True,
        created_at=now - timedelta(minutes=30),
        updated_at=now - timedelta(minutes=30),
    )
    # 1 deactivated/revoked threat
    threat_revoked = ThreatRecordModel(
        url_hash="hash_revoked",
        domain_hash="dom_revoked",
        canonical_url="https://false-positive.com",
        is_active=False,
        created_at=now - timedelta(days=3),
        updated_at=now - timedelta(minutes=10),
    )
    test_db_session.add_all([threat_old, threat_new, threat_revoked])
    await test_db_session.commit()

    app.dependency_overrides[get_db_session] = lambda: test_db_session

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get(
            "/api/v1/threats/delta",
            params={"since": cutoff.isoformat()},
        )

    assert resp.status_code == 200
    data = resp.json()

    # Only new threat should be in added_hashes
    assert len(data["added_hashes"]) == 1
    assert data["added_hashes"][0]["hash"] == "hash_new"

    # Revoked threat should be in removed_hashes
    assert len(data["removed_hashes"]) == 1
    assert data["removed_hashes"][0] == "hash_revoked"

    app.dependency_overrides.clear()
