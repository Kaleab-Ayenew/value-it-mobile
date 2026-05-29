from datetime import datetime

from pydantic import BaseModel, EmailStr


class ClientCreate(BaseModel):
    full_name: str
    email: EmailStr | None = None
    phone_number: str | None = None
    address: str | None = None
    organization: str | None = None


class ClientUpdate(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    phone_number: str | None = None
    address: str | None = None
    organization: str | None = None


class ClientResponse(BaseModel):
    client_id: int
    full_name: str
    email: str | None
    phone_number: str | None
    address: str | None
    organization: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
