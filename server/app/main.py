import os

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic.types import Annotated
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session, lifespan

app = FastAPI(lifespan=lifespan)

# The Flutter web client is served from a different origin, so browsers need CORS.
# Comma-separated list, e.g. "http://client.home.hub,http://localhost:8080".
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("CORS_ALLOW_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {"Hello": "Hello from home hub"}


@app.get("/health")
def health():
    """Liveness probe: the process is up and serving requests. Used by the container healthcheck."""
    return {"status": "ok"}


@app.get("/health/db")
async def health_db(session: Annotated[AsyncSession, Depends(get_session)]):
    await session.execute(text("SELECT 1"))
    return {"status": "ok"}
