from pathlib import Path

import sqlalchemy
from pydantic.networks import lru_cache
from pydantic.types import SecretStr
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    db_host: str
    db_port: int
    db_name: str
    db_username: str
    db_password: SecretStr
    db_pool_size: int
    db_max_overflow: int
    # Logs every SQL statement with its bound parameters; enable only for local debugging.
    db_echo: bool = False
    project_root: Path = Path(__file__).parent.parent

    @property
    def database_url(self):
        return sqlalchemy.URL.create(
            drivername="postgresql+psycopg",
            username=self.db_username,
            password=self.db_password.get_secret_value(),
            host=self.db_host,
            port=self.db_port,
            database=self.db_name,
        )


@lru_cache
def get_settings():
    return Settings()  # type: ignore
