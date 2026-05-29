from datetime import datetime

from pydantic import BaseModel

from app.schemas.project import ProjectResponse


class TimelineEvent(BaseModel):
    label: str
    at: datetime | None
    detail: str | None = None


class ProjectDetailResponse(ProjectResponse):
    valuer_name: str | None = None
    inspector_name: str | None = None
    has_inspection: bool = False
    has_report: bool = False
    report_status: str | None = None
    timeline: list[TimelineEvent] = []
