from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from sqlalchemy.ext.asyncio import AsyncEngine, async_sessionmaker, create_async_engine

from app.core.config import Settings, get_settings


def create_engine_from(settings: Settings) -> AsyncEngine:
    """Builds the app's engine; all pool/engine tuning lives here so it can be unit-tested."""
    return create_async_engine(
        settings.database_url,
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        # Test each connection on checkout so ones killed by a db restart are replaced
        # transparently instead of failing the request.
        pool_pre_ping=True,
        echo=settings.db_echo,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    engine = create_engine_from(get_settings())

    # async_sessionmaker: a factory for new AsyncSession objects.
    # expire_on_commit - don't expire objects after transaction commit
    async_session = async_sessionmaker(engine, expire_on_commit=False)

    yield {"session_factory": async_session}

    await engine.dispose()


async def get_session(request: Request):
    async with request.state.session_factory() as session:
        yield session
