import asyncio
from contextlib import asynccontextmanager
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.api.v1.safari import router as safari_router
from app.api.v1.sms import router as sms_router
from app.api.v1.threats import router as threats_router
from app.core.config import settings
from app.core.redis import close_redis_pool, get_redis_pool
from app.db.models import ThreatRecordModel
from app.db.session import Base, async_session_factory, engine

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Setup Redis pool
    try:
        await get_redis_pool()
    except Exception:
        pass

    # 2. Auto-initialize database tables if not existing
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database schema verified on startup.")
    except Exception as db_err:
        logger.warning(f"Database initialization deferred: {db_err}")

    # 3. Bootstrap initial live threat intelligence if database is empty
    async def bootstrap_feeds_if_empty():
        try:
            async with async_session_factory() as s:
                first_record = (await s.execute(select(ThreatRecordModel))).scalars().first()
                if first_record is None:
                    logger.info("Empty threat database detected; bootstrapping initial feed data...")
                    from worker.ingestion import run_feed_pipeline
                    await run_feed_pipeline("openphish", limit=50)
                    await run_feed_pipeline("phishing_army", limit=50)
                    logger.info("Initial threat feed bootstrap complete.")
        except Exception as e:
            logger.info(f"Background feed bootstrap skipped or deferred: {e}")

    asyncio.create_task(bootstrap_feeds_if_empty())

    yield

    # Cleanup resources on shutdown
    await close_redis_pool()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API v1 Routers
app.include_router(sms_router, prefix="/api/v1")
app.include_router(safari_router, prefix="/api/v1")
app.include_router(threats_router, prefix="/api/v1")


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "environment": settings.ENVIRONMENT}
