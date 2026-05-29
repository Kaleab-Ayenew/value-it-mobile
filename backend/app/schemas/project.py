from datetime import date, datetime

from pydantic import BaseModel

from app.schemas.client import ClientResponse


class ProjectCreate(BaseModel):
    project_name: str
    location: str | None = None
    valuation_purpose: str | None = None
    client_id: int | None = None
    start_date: date | None = None
    end_date: date | None = None


class ProjectUpdate(BaseModel):
    project_name: str | None = None
    location: str | None = None
    valuation_purpose: str | None = None
    client_id: int | None = None
    status: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    archived: bool | None = None


class ProjectAssign(BaseModel):
    valuer_id: int | None = None
    inspector_id: int | None = None


class ProjectResponse(BaseModel):
    project_id: int
    project_name: str
    location: str | None
    valuation_purpose: str | None
    client_id: int | None
    valuer_id: int | None
    inspector_id: int | None
    status: str
    archived: bool = False
    start_date: date | None
    end_date: date | None
    created_at: datetime
    updated_at: datetime
    client: ClientResponse | None = None

    model_config = {"from_attributes": True}
