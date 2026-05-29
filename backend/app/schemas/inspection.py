from datetime import date, datetime

from pydantic import BaseModel


class ChecklistItem(BaseModel):
    area: str
    condition: str | None = None
    notes: str | None = None


class InspectionCreate(BaseModel):
    inspection_date: date | None = None
    observations: str | None = None
    measurements: str | None = None
    remarks: str | None = None
    checklist: list[ChecklistItem] | None = None


class PhotoResponse(BaseModel):
    photo_id: int
    file_path: str
    url: str | None = None
    uploaded_at: datetime

    model_config = {"from_attributes": True}


class InspectionResponse(BaseModel):
    inspection_id: int
    project_id: int
    inspector_id: int
    inspection_date: date | None
    observations: str | None
    measurements: str | None
    remarks: str | None
    checklist_json: str | None = None
    status: str
    created_at: datetime
    photos: list[PhotoResponse] = []

    model_config = {"from_attributes": True}
