from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.deps import require_roles
from app.database import get_db
from app.models import User, ValuationProject, ValuationReport

from app.schemas.analytics import AnalyticsOverview

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/overview", response_model=AnalyticsOverview)
def overview(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    projects = db.query(ValuationProject).filter(ValuationProject.archived.is_(False)).all()
    pending_users = (
        db.query(User).filter(User.account_status == "Pending").count()
    )
    pending_reports = (
        db.query(ValuationReport).filter(ValuationReport.status == "Submitted").count()
    )
    return AnalyticsOverview(
        total_projects=len(projects),
        pending=sum(1 for p in projects if p.status == "Pending"),
        in_progress=sum(1 for p in projects if p.status == "In Progress"),
        completed=sum(1 for p in projects if p.status == "Completed"),
        pending_approvals=pending_users,
        pending_reports=pending_reports,
        active_valuers=db.query(User)
        .filter(User.role == "Valuer", User.account_status == "Active")
        .count(),
        active_inspectors=db.query(User)
        .filter(User.role == "SiteInspector", User.account_status == "Active")
        .count(),
    )
