from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth.deps import get_current_user, require_roles
from app.database import get_db
from app.models import User, ValuationProject
from app.schemas.auth import ApprovalRequest, UserResponse
from app.services.audit import log_action

router = APIRouter(prefix="/users", tags=["users"])


class UserStatusUpdate(BaseModel):
    account_status: str


class UserAvailability(BaseModel):
    user_id: int
    full_name: str
    active_projects: int
    available: bool


class FcmTokenUpdate(BaseModel):
    fcm_token: str


@router.get("", response_model=list[UserResponse])
def list_users(
    role: str | None = None,
    status: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    q = db.query(User)
    if role:
        q = q.filter(User.role == role)
    if status:
        q = q.filter(User.account_status == status)
    return q.order_by(User.full_name).all()


@router.get("/pending", response_model=list[UserResponse])
def pending_users(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    return db.query(User).filter(User.account_status == "Pending").all()


@router.get("/availability", response_model=list[UserAvailability])
def user_availability(
    role: str,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    users = db.query(User).filter(User.role == role, User.account_status == "Active").all()
    out = []
    for u in users:
        if role == "Valuer":
            count = (
                db.query(ValuationProject)
                .filter(
                    ValuationProject.valuer_id == u.user_id,
                    ValuationProject.archived.is_(False),
                    ValuationProject.status != "Completed",
                )
                .count()
            )
        else:
            count = (
                db.query(ValuationProject)
                .filter(
                    ValuationProject.inspector_id == u.user_id,
                    ValuationProject.archived.is_(False),
                    ValuationProject.status != "Completed",
                )
                .count()
            )
        out.append(
            UserAvailability(
                user_id=u.user_id,
                full_name=u.full_name,
                active_projects=count,
                available=count < 4,
            )
        )
    return out


@router.patch("/me/fcm-token")
def update_fcm_token(
    data: FcmTokenUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    user.fcm_token = data.fcm_token
    db.commit()
    return {"ok": True}


@router.patch("/{user_id}/approval", response_model=UserResponse)
def approve_user(
    user_id: int,
    data: ApprovalRequest,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = "Active" if data.approved else "Rejected"
    log_action(db, manager.user_id, "approval", "user", entity_id=user_id, detail=user.account_status)
    db.commit()
    db.refresh(user)
    return user


@router.patch("/{user_id}/status", response_model=UserResponse)
def set_user_status(
    user_id: int,
    data: UserStatusUpdate,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = data.account_status
    log_action(db, manager.user_id, "status", "user", entity_id=user_id, detail=data.account_status)
    db.commit()
    db.refresh(user)
    return user
