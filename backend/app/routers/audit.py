from fastapi import APIRouter, Depends
from pydantic import BaseModel
from datetime import datetime
from sqlalchemy.orm import Session

from app.auth.deps import require_roles
from app.database import get_db
from app.models import AuditLog, User

router = APIRouter(prefix="/audit", tags=["audit"])


class AuditLogResponse(BaseModel):
    log_id: int
    user_id: int | None
    action: str
    entity_type: str
    entity_id: int | None
    detail: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("", response_model=list[AuditLogResponse])
def list_audit(
    limit: int = 100,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    return (
        db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(min(limit, 500)).all()
    )
