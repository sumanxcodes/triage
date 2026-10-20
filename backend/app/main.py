from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.safari import router as safari_router
from app.api.v1.sms import router as sms_router
from app.api.v1.threats import router as threats_router
from app.core.config import settings
from app.core.redis import close_redis_pool, get_redis_pool


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Setup resources on startup
    try:
        await get_redis_pool()
    except Exception:
        # Allow starting even if Redis isn't immediately running (e.g. testing)
        pass
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
