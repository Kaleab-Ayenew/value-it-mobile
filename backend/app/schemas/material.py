from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class MaterialCreate(BaseModel):
    material_name: str
    unit: str
    unit_price: Decimal
    price_source: str | None = None


class MaterialUpdate(BaseModel):
    material_name: str | None = None
    unit: str | None = None
    unit_price: Decimal | None = None
    price_source: str | None = None


class MaterialResponse(BaseModel):
    material_id: int
    material_name: str
    unit: str
    unit_price: Decimal
    price_source: str | None
    last_updated: datetime

    model_config = {"from_attributes": True}
