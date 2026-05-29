from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class LineItem(BaseModel):
    material_name: str
    quantity: float
    unit: str
    unit_price: float
    total: float


class ReportCreate(BaseModel):
    line_items: list[LineItem]
    notes: str | None = None
    status: str = "Submitted"


class ReportResponse(BaseModel):
    report_id: int
    project_id: int
    valuer_id: int
    report_content: str | None
    calculated_value: Decimal | None
    status: str
    report_date: datetime

    model_config = {"from_attributes": True}
