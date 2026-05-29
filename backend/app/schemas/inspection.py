from datetime import date, datetime

from pydantic import BaseModel


class InspectionCreate(BaseModel):
    inspection_date: date | None = None
    observations: str | None = None
    measurements: str | None = None
    remarks: str | None = None


class PhotoResponse(BaseModel):
    photo_id: int
    file_path: str
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
    status: str
    created_at: datetime
    photos: list[PhotoResponse] = []

    model_config = {"from_attributes": True}
