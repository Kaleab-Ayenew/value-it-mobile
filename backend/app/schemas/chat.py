from datetime import datetime

from pydantic import BaseModel, Field


class ChatMessageCreate(BaseModel):
    message_content: str = Field(min_length=1, max_length=2000)


class ChatMessageResponse(BaseModel):
    message_id: int
    project_id: int
    sender_id: int
    sender_name: str | None = None
    message_content: str
    sent_at: datetime

    model_config = {"from_attributes": True}
