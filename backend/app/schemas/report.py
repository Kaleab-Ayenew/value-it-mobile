from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class LineItem(BaseModel):
    material_name: str
    quantity: float
    unit: str
    unit_price: float
    total: float


class ReportCreate(BaseModel):
    line_items: list[LineItem]
    notes: str | None = None
    status: str = "Draft"


class ReportReject(BaseModel):
    feedback: str = Field(min_length=1)


class ReportResponse(BaseModel):
    report_id: int
    project_id: int
    valuer_id: int
    report_content: str | None
    calculated_value: Decimal | None
    status: str
    manager_feedback: str | None = None
    report_date: datetime
    line_items: list[LineItem] | None = None
    notes: str | None = None

    model_config = {"from_attributes": True}
