"""Smoke test for the Alembic setup the `migrate` compose service runs.

Runs the same command as the container (`alembic -c alembic.ini upgrade head`), in
offline (--sql) mode so no database is needed. It runs in a subprocess from an unrelated
directory without pytest's sys.path, so alembic.ini's own settings (script_location,
prepend_sys_path, logging) are what make it work - exactly as in the container.
"""

import os
import subprocess
import sys
from pathlib import Path

ALEMBIC_INI = Path(__file__).resolve().parents[1] / "alembic.ini"

DB_ENV = {
    "DB_HOST": "db",
    "DB_PORT": "5432",
    "DB_NAME": "appdb",
    "DB_USERNAME": "admin",
    "DB_PASSWORD": "s3cret",
    "DB_POOL_SIZE": "10",
    "DB_MAX_OVERFLOW": "10",
}


def test_migrations_render_to_head_offline(tmp_path):
    env = {key: value for key, value in os.environ.items() if key != "PYTHONPATH"}
    env.update(DB_ENV)

    result = subprocess.run(
        [sys.executable, "-m", "alembic", "-c", str(ALEMBIC_INI), "upgrade", "head", "--sql"],
        cwd=tmp_path,
        env=env,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stderr
    assert "CREATE TABLE alembic_version" in result.stdout
    assert "INSERT INTO alembic_version" in result.stdout
