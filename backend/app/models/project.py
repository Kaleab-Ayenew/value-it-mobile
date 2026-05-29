from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ValuationProject(Base):
    __tablename__ = "valuation_projects"

    project_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    project_name: Mapped[str] = mapped_column(String(100))
    location: Mapped[str | None] = mapped_column(String(200), nullable=True)
    valuation_purpose: Mapped[str | None] = mapped_column(String(100), nullable=True)
    client_id: Mapped[int | None] = mapped_column(ForeignKey("clients.client_id"), nullable=True)
    valuer_id: Mapped[int | None] = mapped_column(ForeignKey("users.user_id"), nullable=True)
    inspector_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.user_id"), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), default="Pending")
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    client = relationship("Client", back_populates="projects")
    valuer = relationship(
        "User", back_populates="valuer_projects", foreign_keys=[valuer_id]
    )
    inspector = relationship(
        "User", back_populates="inspector_projects", foreign_keys=[inspector_id]
    )
    inspection = relationship(
        "Inspection", back_populates="project", uselist=False, cascade="all, delete-orphan"
    )
    report = relationship(
        "ValuationReport", back_populates="project", uselist=False, cascade="all, delete-orphan"
    )
