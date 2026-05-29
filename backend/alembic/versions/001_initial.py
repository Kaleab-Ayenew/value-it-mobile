"""initial schema

Revision ID: 001
Revises:
Create Date: 2026-05-29

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("user_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("full_name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(100), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.String(20), nullable=False),
        sa.Column("phone_number", sa.String(20), nullable=True),
        sa.Column("account_status", sa.String(20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("user_id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "clients",
        sa.Column("client_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("full_name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(100), nullable=True),
        sa.Column("phone_number", sa.String(20), nullable=True),
        sa.Column("address", sa.Text(), nullable=True),
        sa.Column("organization", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("client_id"),
    )

    op.create_table(
        "material_pricing",
        sa.Column("material_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("material_name", sa.String(100), nullable=False),
        sa.Column("unit", sa.String(20), nullable=False),
        sa.Column("unit_price", sa.Numeric(10, 2), nullable=False),
        sa.Column("price_source", sa.String(100), nullable=True),
        sa.Column("last_updated", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("material_id"),
    )

    op.create_table(
        "valuation_projects",
        sa.Column("project_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("project_name", sa.String(100), nullable=False),
        sa.Column("location", sa.String(200), nullable=True),
        sa.Column("valuation_purpose", sa.String(100), nullable=True),
        sa.Column("client_id", sa.Integer(), nullable=True),
        sa.Column("valuer_id", sa.Integer(), nullable=True),
        sa.Column("inspector_id", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["client_id"], ["clients.client_id"]),
        sa.ForeignKeyConstraint(["valuer_id"], ["users.user_id"]),
        sa.ForeignKeyConstraint(["inspector_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("project_id"),
    )

    op.create_table(
        "inspections",
        sa.Column("inspection_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("project_id", sa.Integer(), nullable=False),
        sa.Column("inspector_id", sa.Integer(), nullable=False),
        sa.Column("inspection_date", sa.Date(), nullable=True),
        sa.Column("observations", sa.Text(), nullable=True),
        sa.Column("measurements", sa.Text(), nullable=True),
        sa.Column("remarks", sa.Text(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["valuation_projects.project_id"]),
        sa.ForeignKeyConstraint(["inspector_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("inspection_id"),
        sa.UniqueConstraint("project_id"),
    )

    op.create_table(
        "site_photos",
        sa.Column("photo_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("inspection_id", sa.Integer(), nullable=False),
        sa.Column("file_path", sa.String(500), nullable=False),
        sa.Column("uploaded_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["inspection_id"], ["inspections.inspection_id"]),
        sa.PrimaryKeyConstraint("photo_id"),
    )

    op.create_table(
        "valuation_reports",
        sa.Column("report_id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("project_id", sa.Integer(), nullable=False),
        sa.Column("valuer_id", sa.Integer(), nullable=False),
        sa.Column("report_content", sa.Text(), nullable=True),
        sa.Column("calculated_value", sa.Numeric(15, 2), nullable=True),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("report_date", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["valuation_projects.project_id"]),
        sa.ForeignKeyConstraint(["valuer_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("report_id"),
        sa.UniqueConstraint("project_id"),
    )


def downgrade() -> None:
    op.drop_table("valuation_reports")
    op.drop_table("site_photos")
    op.drop_table("inspections")
    op.drop_table("valuation_projects")
    op.drop_table("material_pricing")
    op.drop_table("clients")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
