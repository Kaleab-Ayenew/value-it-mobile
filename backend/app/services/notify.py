from sqlalchemy.orm import Session

from app.models.notification import Notification


def notify_user(
    db: Session,
    user_id: int,
    title: str,
    content: str,
    notification_type: str = "System",
    project_id: int | None = None,
) -> Notification:
    n = Notification(
        user_id=user_id,
        title=title,
        content=content,
        notification_type=notification_type,
        project_id=project_id,
        status="Unread",
    )
    db.add(n)
    db.flush()
    return n
