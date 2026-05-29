from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class MaterialResponse(BaseModel):
    material_id: int
    material_name: str
    unit: str
    unit_price: Decimal
    price_source: str | None
    last_updated: datetime

    model_config = {"from_attributes": True}
