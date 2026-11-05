import asyncio

import pytest
from fastapi import FastAPI

from app.core.config import Settings
from app.db import session as db_session
from app.db.session import create_engine_from, lifespan


def make_settings(**overrides):
    values = {
        "db_host": "db",
        "db_port": 5432,
        "db_name": "appdb",
        "db_username": "admin",
        "db_password": "s3cret",
        "db_pool_size": 7,
        "db_max_overflow": 3,
    }
    return Settings(**(values | overrides))


@pytest.fixture
def engine_for():
    """Builds engines from settings and disposes them. Engines connect lazily, so no DB is
    needed."""
    engines = []

    def build(settings):
        engine = create_engine_from(settings)
        engines.append(engine)
        return engine

    yield build
    for engine in engines:
        engine.sync_engine.dispose()


def test_engine_uses_pool_settings(engine_for):
    pool = engine_for(make_settings()).sync_engine.pool

    assert pool.size() == 7
    assert pool._max_overflow == 3  # no public accessor for the configured max overflow


def test_engine_replaces_dead_connections_on_checkout(engine_for):
    # Without pre-ping, connections killed by a db restart surface as request errors.
    assert engine_for(make_settings()).sync_engine.pool._pre_ping is True


def test_engine_does_not_echo_sql_by_default(engine_for):
    # echo logs every statement with its bound parameters (PII once models exist).
    assert engine_for(make_settings()).echo is False


def test_engine_echo_is_configurable(engine_for):
    assert engine_for(make_settings(db_echo=True)).echo is True


def test_db_echo_is_read_from_environment(monkeypatch):
    for key, value in {
        "DB_HOST": "db",
        "DB_PORT": "5432",
        "DB_NAME": "appdb",
        "DB_USERNAME": "admin",
        "DB_PASSWORD": "s3cret",
        "DB_POOL_SIZE": "7",
        "DB_MAX_OVERFLOW": "3",
        "DB_ECHO": "true",
    }.items():
        monkeypatch.setenv(key, value)

    assert Settings().db_echo is True


def test_lifespan_builds_engine_from_settings(monkeypatch):
    monkeypatch.setattr(db_session, "get_settings", lambda: make_settings(db_pool_size=4))

    async def enter_lifespan():
        async with lifespan(FastAPI()) as state:
            return state["session_factory"].kw["bind"].sync_engine.pool.size()

    assert asyncio.run(enter_lifespan()) == 4
