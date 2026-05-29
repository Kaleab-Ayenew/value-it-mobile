from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class ValuationReport(Base):
    __tablename__ = "valuation_reports"

    report_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    project_id: Mapped[int] = mapped_column(
        ForeignKey("valuation_projects.project_id"), unique=True
    )
    valuer_id: Mapped[int] = mapped_column(ForeignKey("users.user_id"))
    report_content: Mapped[str | None] = mapped_column(Text, nullable=True)
    calculated_value: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="Draft")
    manager_feedback: Mapped[str | None] = mapped_column(Text, nullable=True)
    report_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    project = relationship("ValuationProject", back_populates="report")
