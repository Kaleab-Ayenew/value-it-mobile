from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.deps import get_current_user, require_roles
from app.database import get_db
from app.models import User
from app.schemas.auth import ApprovalRequest, UserResponse

router = APIRouter(prefix="/users", tags=["users"])


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


@router.patch("/{user_id}/approval", response_model=UserResponse)
def approve_user(
    user_id: int,
    data: ApprovalRequest,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = "Active" if data.approved else "Rejected"
    db.commit()
    db.refresh(user)
    return user
