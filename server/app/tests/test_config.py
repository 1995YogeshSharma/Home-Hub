import pytest
from pydantic import ValidationError

from app.core.config import Settings

# Config comes only from environment variables (supplied by docker compose); there is
# no .env file, so each test sets exactly the variables it needs.
DB_ENV = {
    "DB_HOST": "db",
    "DB_PORT": "5432",
    "DB_NAME": "appdb",
    "DB_USERNAME": "admin",
    "DB_PASSWORD": "s3cret",
    "DB_POOL_SIZE": "10",
    "DB_MAX_OVERFLOW": "10",
}


def _settings_from(monkeypatch, env):
    for key, value in env.items():
        monkeypatch.setenv(key, value)
    return Settings()


def test_database_url_uses_real_password_not_masked_secret(monkeypatch):
    settings = _settings_from(monkeypatch, DB_ENV)

    assert settings.database_url.password == "s3cret"


def test_database_url_is_built_from_environment(monkeypatch):
    url = _settings_from(monkeypatch, DB_ENV).database_url

    assert (url.drivername, url.host, url.port, url.database, url.username) == (
        "postgresql+psycopg",
        "db",
        5432,
        "appdb",
        "admin",
    )


def test_missing_required_variable_fails_fast(monkeypatch):
    # A misconfigured deployment must fail at startup, not fall back to a default host.
    env = {key: value for key, value in DB_ENV.items() if key != "DB_HOST"}
    monkeypatch.delenv("DB_HOST", raising=False)

    with pytest.raises(ValidationError, match="db_host"):
        _settings_from(monkeypatch, env)
