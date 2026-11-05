"""Contract tests for the shared declarative Base.

Constraint names end up baked into the database by the first migration, so these tests
pin the naming convention and type mappings before any real table exists.
"""

from datetime import datetime
from typing import Any

import pytest
from sqlalchemy import CheckConstraint, ForeignKey, Index, UniqueConstraint
from sqlalchemy.dialects import postgresql, sqlite
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.schema import CreateIndex, CreateTable

from app.models.base import Base

EXPECTED_NAMING_CONVENTION = {
    # column_0_N_* uses *all* columns, so composite constraints sharing a leading
    # column (e.g. group_id) don't collide on the same name.
    "ix": "ix_%(table_name)s_%(column_0_N_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


@pytest.fixture(scope="module")
def probe_models():
    """Throwaway models defined on the real Base, so they exercise its actual config.

    Module-scoped so the classes are declared once (redeclaring a class name on the same
    registry warns). The tables are removed from Base.metadata afterwards, so they never
    leak into other tests or into what Alembic would see.
    """

    class ProbeParent(Base):
        __tablename__ = "probe_parents"

        id: Mapped[int] = mapped_column(primary_key=True)

    class ProbeChild(Base):
        __tablename__ = "probe_children"
        __table_args__ = (
            UniqueConstraint("parent_id", "title"),
            Index(None, "parent_id", "created_at"),
            CheckConstraint("length(title) > 0", name="title_not_empty"),
        )

        id: Mapped[int] = mapped_column(primary_key=True)
        parent_id: Mapped[int] = mapped_column(ForeignKey("probe_parents.id"))
        title: Mapped[str]
        created_at: Mapped[datetime]
        body: Mapped[dict[str, Any]]

    yield ProbeParent, ProbeChild

    for model in (ProbeChild, ProbeParent):
        Base.metadata.remove(model.__table__)


@pytest.fixture(scope="module")
def child_ddl(probe_models):
    _, child = probe_models
    return str(CreateTable(child.__table__).compile(dialect=postgresql.dialect()))


def test_metadata_uses_naming_convention():
    convention = Base.metadata.naming_convention

    for key, template in EXPECTED_NAMING_CONVENTION.items():
        assert convention[key] == template, f"naming convention for {key!r}"


def test_datetime_maps_to_timezone_aware_timestamp(child_ddl):
    assert "created_at TIMESTAMP WITH TIME ZONE NOT NULL" in child_ddl


def test_dict_maps_to_jsonb_on_postgresql(child_ddl):
    assert "body JSONB NOT NULL" in child_ddl


def test_dict_falls_back_to_json_on_other_dialects(probe_models):
    _, child = probe_models

    assert child.__table__.c.body.type.compile(dialect=sqlite.dialect()) == "JSON"


def test_primary_key_follows_convention(child_ddl):
    assert "CONSTRAINT pk_probe_children PRIMARY KEY (id)" in child_ddl


def test_foreign_key_follows_convention(child_ddl):
    assert "CONSTRAINT fk_probe_children_parent_id_probe_parents FOREIGN KEY" in child_ddl


def test_composite_unique_constraint_names_every_column(child_ddl):
    assert "CONSTRAINT uq_probe_children_parent_id_title UNIQUE (parent_id, title)" in child_ddl


def test_check_constraint_follows_convention(child_ddl):
    assert "CONSTRAINT ck_probe_children_title_not_empty CHECK" in child_ddl


def test_composite_index_names_every_column(probe_models):
    _, child = probe_models
    (index,) = child.__table__.indexes

    ddl = str(CreateIndex(index).compile(dialect=postgresql.dialect()))

    assert ddl.startswith("CREATE INDEX ix_probe_children_parent_id_created_at ON")
