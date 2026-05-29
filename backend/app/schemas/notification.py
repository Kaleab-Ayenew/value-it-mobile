from datetime import datetime

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    notification_id: int
    user_id: int
    project_id: int | None
    title: str
    content: str
    notification_type: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
