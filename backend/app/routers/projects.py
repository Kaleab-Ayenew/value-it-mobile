import json
import os
import uuid
from decimal import Decimal

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session, joinedload

from app.auth.deps import get_current_user, require_roles
from app.config import settings
from app.database import get_db
from app.models import (
    Inspection,
    SitePhoto,
    User,
    ValuationProject,
    ValuationReport,
)
from app.schemas.inspection import InspectionCreate, InspectionResponse
from app.schemas.project import (
    ProjectAssign,
    ProjectCreate,
    ProjectResponse,
    ProjectUpdate,
)
from app.schemas.report import ReportCreate, ReportResponse

router = APIRouter(prefix="/projects", tags=["projects"])


def _project_query(db: Session):
    return db.query(ValuationProject).options(joinedload(ValuationProject.client))


def _can_access(project: ValuationProject, user: User) -> bool:
    if user.role == "Manager":
        return True
    if user.role == "Valuer" and project.valuer_id == user.user_id:
        return True
    if user.role == "SiteInspector" and project.inspector_id == user.user_id:
        return True
    return False


@router.get("", response_model=list[ProjectResponse])
def list_projects(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    q = _project_query(db)
    if user.role == "Valuer":
        q = q.filter(ValuationProject.valuer_id == user.user_id)
    elif user.role == "SiteInspector":
        q = q.filter(ValuationProject.inspector_id == user.user_id)
    return q.order_by(ValuationProject.created_at.desc()).all()


@router.post("", response_model=ProjectResponse, status_code=201)
def create_project(
    data: ProjectCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    project = ValuationProject(**data.model_dump(), status="Pending")
    db.add(project)
    db.commit()
    db.refresh(project)
    return _project_query(db).filter(ValuationProject.project_id == project.project_id).first()


@router.get("/{project_id}", response_model=ProjectResponse)
def get_project(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = _project_query(db).filter(ValuationProject.project_id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if not _can_access(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    return project


@router.patch("/{project_id}", response_model=ProjectResponse)
def update_project(
    project_id: int,
    data: ProjectUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(project, k, v)
    db.commit()
    return _project_query(db).filter(ValuationProject.project_id == project_id).first()


@router.patch("/{project_id}/assign", response_model=ProjectResponse)
def assign_project(
    project_id: int,
    data: ProjectAssign,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if data.valuer_id is not None:
        project.valuer_id = data.valuer_id
    if data.inspector_id is not None:
        project.inspector_id = data.inspector_id
    if project.valuer_id and project.inspector_id:
        project.status = "In Progress"
    db.commit()
    return _project_query(db).filter(ValuationProject.project_id == project_id).first()


@router.post("/{project_id}/inspection", response_model=InspectionResponse, status_code=201)
def submit_inspection(
    project_id: int,
    data: InspectionCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("SiteInspector")),
):
    project = db.get(ValuationProject, project_id)
    if not project or project.inspector_id != user.user_id:
        raise HTTPException(status_code=403, detail="Not assigned to this project")
    if project.inspection:
        raise HTTPException(status_code=400, detail="Inspection already submitted")
    inspection = Inspection(
        project_id=project_id,
        inspector_id=user.user_id,
        **data.model_dump(),
        status="Submitted",
    )
    db.add(inspection)
    db.commit()
    db.refresh(inspection)
    return db.query(Inspection).options(joinedload(Inspection.photos)).get(inspection.inspection_id)


@router.get("/{project_id}/inspection", response_model=InspectionResponse)
def get_inspection(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.get(ValuationProject, project_id)
    if not project or not _can_access(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    if not project.inspection:
        raise HTTPException(status_code=404, detail="No inspection yet")
    return (
        db.query(Inspection)
        .options(joinedload(Inspection.photos))
        .filter(Inspection.project_id == project_id)
        .first()
    )


@router.post("/{project_id}/inspection/photos", response_model=InspectionResponse)
async def upload_photos(
    project_id: int,
    files: list[UploadFile] = File(...),
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("SiteInspector")),
):
    project = db.get(ValuationProject, project_id)
    if not project or project.inspector_id != user.user_id:
        raise HTTPException(status_code=403, detail="Not assigned")
    if not project.inspection:
        raise HTTPException(status_code=400, detail="Submit inspection first")
    os.makedirs(settings.upload_dir, exist_ok=True)
    for f in files:
        ext = os.path.splitext(f.filename or "img.jpg")[1] or ".jpg"
        name = f"{uuid.uuid4()}{ext}"
        path = os.path.join(settings.upload_dir, name)
        content = await f.read()
        with open(path, "wb") as out:
            out.write(content)
        photo = SitePhoto(inspection_id=project.inspection.inspection_id, file_path=name)
        db.add(photo)
    db.commit()
    return (
        db.query(Inspection)
        .options(joinedload(Inspection.photos))
        .filter(Inspection.project_id == project_id)
        .first()
    )


@router.post("/{project_id}/report", response_model=ReportResponse, status_code=201)
def submit_report(
    project_id: int,
    data: ReportCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("Valuer")),
):
    project = db.get(ValuationProject, project_id)
    if not project or project.valuer_id != user.user_id:
        raise HTTPException(status_code=403, detail="Not assigned")
    if not project.inspection:
        raise HTTPException(status_code=400, detail="Inspection required first")
    total = sum(item.total for item in data.line_items)
    content = json.dumps(
        {"line_items": [i.model_dump() for i in data.line_items], "notes": data.notes}
    )
    if project.report:
        project.report.report_content = content
        project.report.calculated_value = Decimal(str(total))
        project.report.status = data.status
        report = project.report
    else:
        report = ValuationReport(
            project_id=project_id,
            valuer_id=user.user_id,
            report_content=content,
            calculated_value=Decimal(str(total)),
            status=data.status,
        )
        db.add(report)
    project.status = "In Progress"
    db.commit()
    db.refresh(report)
    return report


@router.get("/{project_id}/report", response_model=ReportResponse)
def get_report(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.get(ValuationProject, project_id)
    if not project or not _can_access(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    if not project.report:
        raise HTTPException(status_code=404, detail="No report yet")
    return project.report


@router.patch("/{project_id}/report/approve", response_model=ReportResponse)
def approve_report(
    project_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project or not project.report:
        raise HTTPException(status_code=404, detail="No report to approve")
    project.report.status = "Approved"
    project.status = "Completed"
    db.commit()
    db.refresh(project.report)
    return project.report
