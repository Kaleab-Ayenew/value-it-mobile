from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=6)
    phone_number: str | None = None
    role: Literal["Manager", "Valuer", "SiteInspector"]


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    user_id: int
    full_name: str
    email: str
    role: str
    phone_number: str | None
    account_status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ApprovalRequest(BaseModel):
    approved: bool
