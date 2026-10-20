from unittest.mock import patch
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from worker.celery_app import celery_app

# Prevent Celery network calls during tests
celery_app.conf.task_always_eager = True


@pytest.fixture(autouse=True)
def mock_celery_task():
    with patch.object(celery_app, "send_task") as mock:
        yield mock


class MockRedisPipeline:
    def __init__(self, exists_result=False):
        self.exists_result = exists_result
        self.calls = []

    def exists(self, key):
        self.calls.append(key)
        return self

    async def execute(self):
        return [self.exists_result for _ in self.calls]


class MockRedisClient:
    def __init__(self, key_exists=False):
        self.key_exists = key_exists

    def pipeline(self):
        return MockRedisPipeline(exists_result=self.key_exists)

    async def exists(self, key):
        return 1 if self.key_exists else 0


@pytest.fixture
def mock_redis_clean():
    return MockRedisClient(key_exists=False)


@pytest.fixture
def mock_redis_with_threat():
    return MockRedisClient(key_exists=True)


@pytest.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
