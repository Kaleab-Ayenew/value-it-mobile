from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Inspection(Base):
    __tablename__ = "inspections"

    inspection_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    project_id: Mapped[int] = mapped_column(
        ForeignKey("valuation_projects.project_id"), unique=True
    )
    inspector_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"))
    inspection_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    observations: Mapped[str | None] = mapped_column(Text, nullable=True)
    measurements: Mapped[str | None] = mapped_column(Text, nullable=True)
    remarks: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="Submitted")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    project = relationship("ValuationProject", back_populates="inspection")
    photos = relationship("SitePhoto", back_populates="inspection", cascade="all, delete-orphan")


class SitePhoto(Base):
    __tablename__ = "site_photos"

    photo_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    inspection_id: Mapped[int] = mapped_column(ForeignKey("inspections.inspection_id"))
    file_path: Mapped[str] = mapped_column(String(500))
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    inspection = relationship("Inspection", back_populates="photos")
