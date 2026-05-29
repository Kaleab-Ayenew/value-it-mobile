from pydantic import BaseModel


class AnalyticsOverview(BaseModel):
    total_projects: int
    pending: int
    in_progress: int
    completed: int
    pending_approvals: int
    pending_reports: int
    active_valuers: int
    active_inspectors: int
