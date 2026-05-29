from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class MaterialPricing(Base):
    __tablename__ = "material_pricing"

    material_id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    material_name: Mapped[str] = mapped_column(String(100))
    unit: Mapped[str] = mapped_column(String(20))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    price_source: Mapped[str | None] = mapped_column(String(100), nullable=True)
    last_updated: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
