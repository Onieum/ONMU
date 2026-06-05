"""create worker_ai schema scaffold

Revision ID: 0001_worker_ai_schema
Revises:
Create Date: 2026-06-06
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0001_worker_ai_schema"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("create schema if not exists worker_ai")
    op.create_table(
        "ai_job_runs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("outbox_event_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("job_type", sa.Text(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False, server_default="pending"),
        sa.Column("input_metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("result_metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        schema="worker_ai",
    )
    op.create_table(
        "prompt_runs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("ai_job_run_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("prompt_kind", sa.Text(), nullable=False),
        sa.Column("model_name", sa.Text(), nullable=True),
        sa.Column("status", sa.Text(), nullable=False, server_default="pending"),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        schema="worker_ai",
    )
    op.create_table(
        "feature_extraction_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("subject_ref", sa.Text(), nullable=False),
        sa.Column("feature_kind", sa.Text(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False, server_default="pending"),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        schema="worker_ai",
    )


def downgrade() -> None:
    op.drop_table("feature_extraction_jobs", schema="worker_ai")
    op.drop_table("prompt_runs", schema="worker_ai")
    op.drop_table("ai_job_runs", schema="worker_ai")
