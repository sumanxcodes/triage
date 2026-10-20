from unittest.mock import patch
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from worker.celery_app import celery_app

# Prevent Celery network calls during tests
celery_app.conf.task_always_eager = True


class MockRedisPipeline:
    def __init__(self, storage):
        self.storage = storage
        self.commands = []

    def set(self, key, value):
        self.commands.append(("set", key, value))
        return self

    def exists(self, key):
        self.commands.append(("exists", key))
        return self

    def mget(self, keys):
        self.commands.append(("mget", keys))
        return self

    async def execute(self):
        results = []
        for cmd in self.commands:
            action = cmd[0]
            if action == "set":
                self.storage[cmd[1]] = cmd[2]
                results.append(True)
            elif action == "exists":
                results.append(1 if cmd[1] in self.storage else 0)
            elif action == "mget":
                results.append([self.storage.get(k) for k in cmd[1]])
        self.commands.clear()
        return results


class InMemoryRedis:
    def __init__(self):
        self.storage = {}

    def pipeline(self):
        return MockRedisPipeline(self.storage)

    async def get(self, key):
        return self.storage.get(key)

    async def set(self, key, value):
        self.storage[key] = value

    async def exists(self, key):
        return 1 if key in self.storage else 0

    async def mget(self, keys):
        return [self.storage.get(k) for k in keys]


@pytest.fixture
def in_memory_redis():
    return InMemoryRedis()


@pytest.fixture(autouse=True)
def mock_celery_task():
    with patch.object(celery_app, "send_task") as mock:
        yield mock


@pytest.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
