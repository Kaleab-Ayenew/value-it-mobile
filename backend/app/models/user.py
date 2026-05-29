from datetime import datetime

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    user_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    full_name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(20))
    phone_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    account_status: Mapped[str] = mapped_column(String(20), default="Pending")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    valuer_projects = relationship(
        "ValuationProject", back_populates="valuer", foreign_keys="ValuationProject.valuer_id"
    )
    inspector_projects = relationship(
        "ValuationProject",
        back_populates="inspector",
        foreign_keys="ValuationProject.inspector_id",
    )
