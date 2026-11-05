"""baseline

Revision ID: dc37ecf5dd29
Revises:
Create Date: 2026-11-05 14:33:13.512226

"""

from collections.abc import Sequence

# revision identifiers, used by Alembic.
revision: str = "dc37ecf5dd29"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
