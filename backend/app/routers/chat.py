from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth.deps import get_current_user
from app.database import get_db
from app.models import ChatMessage, User, ValuationProject
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse
from app.auth.access import can_access_project

router = APIRouter(prefix="/projects", tags=["chat"])


@router.get("/{project_id}/chat", response_model=list[ChatMessageResponse])
def list_messages(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.get(ValuationProject, project_id)
    if not project or not can_access_project(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    rows = (
        db.query(ChatMessage, User.full_name)
        .join(User, ChatMessage.sender_id == User.user_id)
        .filter(ChatMessage.project_id == project_id)
        .order_by(ChatMessage.sent_at.asc())
        .all()
    )
    return [
        ChatMessageResponse(
            message_id=m.message_id,
            project_id=m.project_id,
            sender_id=m.sender_id,
            sender_name=name,
            message_content=m.message_content,
            sent_at=m.sent_at,
        )
        for m, name in rows
    ]


@router.post("/{project_id}/chat", response_model=ChatMessageResponse, status_code=201)
def post_message(
    project_id: int,
    data: ChatMessageCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.get(ValuationProject, project_id)
    if not project or not can_access_project(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    msg = ChatMessage(
        project_id=project_id,
        sender_id=user.user_id,
        message_content=data.message_content,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return ChatMessageResponse(
        message_id=msg.message_id,
        project_id=msg.project_id,
        sender_id=msg.sender_id,
        sender_name=user.full_name,
        message_content=msg.message_content,
        sent_at=msg.sent_at,
    )
