import json
from decimal import Decimal

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import Response
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.auth.access import can_access_project
from app.auth.deps import get_current_user, require_roles
from app.database import get_db
from app.models import Inspection, SitePhoto, User, ValuationProject, ValuationReport
from app.schemas.inspection import InspectionCreate, InspectionResponse, PhotoResponse
from app.schemas.project import ProjectAssign, ProjectCreate, ProjectResponse, ProjectUpdate
from app.schemas.project_detail import ProjectDetailResponse, TimelineEvent
from app.schemas.report import ReportCreate, ReportReject, ReportResponse, LineItem
from app.services.audit import log_action
from app.services.notify import notify_user
from app.services.pdf import build_report_pdf
from app.services.storage import public_url, upload_bytes
from app.services.email_svc import send_report_email_sync
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/projects", tags=["projects"])


def _project_query(db: Session):
    return db.query(ValuationProject).options(joinedload(ValuationProject.client))


def _enrich_inspection(insp: Inspection) -> InspectionResponse:
    data = InspectionResponse.model_validate(insp)
    photos = []
    for p in insp.photos:
        pr = PhotoResponse.model_validate(p)
        photos.append(pr.model_copy(update={"url": public_url(p.file_path)}))
    return data.model_copy(update={"photos": photos})


def _enrich_report(report: ValuationReport) -> ReportResponse:
    line_items = None
    notes = None
    if report.report_content:
        try:
            parsed = json.loads(report.report_content)
            line_items = [LineItem(**i) for i in parsed.get("line_items", [])]
            notes = parsed.get("notes")
        except (json.JSONDecodeError, TypeError):
            pass
    return ReportResponse(
        report_id=report.report_id,
        project_id=report.project_id,
        valuer_id=report.valuer_id,
        report_content=report.report_content,
        calculated_value=report.calculated_value,
        status=report.status,
        manager_feedback=report.manager_feedback,
        report_date=report.report_date,
        line_items=line_items,
        notes=notes,
    )


@router.get("", response_model=list[ProjectResponse])
def list_projects(
    q: str | None = None,
    status: str | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    query = _project_query(db)
    if not include_archived:
        query = query.filter(ValuationProject.archived.is_(False))
    if user.role == "Valuer":
        query = query.filter(ValuationProject.valuer_id == user.user_id)
    elif user.role == "SiteInspector":
        query = query.filter(ValuationProject.inspector_id == user.user_id)
    if status:
        query = query.filter(ValuationProject.status == status)
    if q:
        like = f"%{q}%"
        query = query.filter(
            or_(ValuationProject.project_name.ilike(like), ValuationProject.location.ilike(like))
        )
    return query.order_by(ValuationProject.created_at.desc()).all()


@router.post("", response_model=ProjectResponse, status_code=201)
def create_project(
    data: ProjectCreate,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    project = ValuationProject(**data.model_dump(), status="Pending")
    db.add(project)
    db.flush()
    log_action(db, manager.user_id, "create", "project", entity_id=project.project_id, detail=project.project_name)
    db.commit()
    db.refresh(project)
    return _project_query(db).filter(ValuationProject.project_id == project.project_id).first()


@router.get("/{project_id}/detail", response_model=ProjectDetailResponse)
def project_detail(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = _project_query(db).filter(ValuationProject.project_id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if not can_access_project(project, user):
        raise HTTPException(status_code=403, detail="Access denied")

    valuer_name = inspector_name = None
    if project.valuer_id:
        v = db.get(User, project.valuer_id)
        valuer_name = v.full_name if v else None
    if project.inspector_id:
        i = db.get(User, project.inspector_id)
        inspector_name = i.full_name if i else None

    timeline = [TimelineEvent(label="Project created", at=project.created_at)]
    if project.valuer_id and project.inspector_id:
        timeline.append(TimelineEvent(label="Team assigned", at=project.updated_at))
    if project.inspection:
        timeline.append(
            TimelineEvent(label="Inspection submitted", at=project.inspection.created_at)
        )
    if project.report:
        timeline.append(
            TimelineEvent(
                label=f"Report {project.report.status}",
                at=project.report.report_date,
                detail=project.report.manager_feedback,
            )
        )

    base = ProjectResponse.model_validate(project)
    return ProjectDetailResponse(
        **base.model_dump(),
        valuer_name=valuer_name,
        inspector_name=inspector_name,
        has_inspection=project.inspection is not None,
        has_report=project.report is not None,
        report_status=project.report.status if project.report else None,
        timeline=timeline,
    )


@router.get("/{project_id}", response_model=ProjectResponse)
def get_project(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = _project_query(db).filter(ValuationProject.project_id == project_id).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if not can_access_project(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    return project


@router.patch("/{project_id}", response_model=ProjectResponse)
def update_project(
    project_id: int,
    data: ProjectUpdate,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(project, k, v)
    log_action(db, manager.user_id, "update", "project", entity_id=project_id)
    db.commit()
    return _project_query(db).filter(ValuationProject.project_id == project_id).first()


@router.patch("/{project_id}/assign", response_model=ProjectResponse)
def assign_project(
    project_id: int,
    data: ProjectAssign,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if data.valuer_id is not None:
        project.valuer_id = data.valuer_id
        notify_user(
            db,
            data.valuer_id,
            "New valuation assignment",
            f"You were assigned to project: {project.project_name}",
            "Project",
            project_id,
        )
    if data.inspector_id is not None:
        project.inspector_id = data.inspector_id
        notify_user(
            db,
            data.inspector_id,
            "New inspection assignment",
            f"Site inspection required: {project.project_name}",
            "Project",
            project_id,
        )
    if project.valuer_id and project.inspector_id:
        project.status = "In Progress"
    log_action(db, manager.user_id, "assign", "project", entity_id=project_id)
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

    payload = data.model_dump(exclude={"checklist"})
    if data.checklist:
        payload["checklist_json"] = json.dumps([c.model_dump() for c in data.checklist])

    if project.inspection:
        for k, v in payload.items():
            setattr(project.inspection, k, v)
        project.inspection.status = "Submitted"
        insp = project.inspection
    else:
        insp = Inspection(
            project_id=project_id,
            inspector_id=user.user_id,
            **payload,
            status="Submitted",
        )
        db.add(insp)

    if project.valuer_id:
        notify_user(
            db,
            project.valuer_id,
            "Inspection ready",
            f"Inspection data submitted for {project.project_name}",
            "Project",
            project_id,
        )
    log_action(db, user.user_id, "submit", "inspection", entity_id=project_id)
    db.commit()
    insp = (
        db.query(Inspection)
        .options(joinedload(Inspection.photos))
        .filter(Inspection.project_id == project_id)
        .first()
    )
    return _enrich_inspection(insp)


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
    return _enrich_inspection(project.inspection)


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
    for f in files:
        content = await f.read()
        key = upload_bytes(content, f.filename or "photo.jpg", f.content_type or "image/jpeg")
        db.add(SitePhoto(inspection_id=project.inspection.inspection_id, file_path=key))
    db.commit()
    insp = (
        db.query(Inspection)
        .options(joinedload(Inspection.photos))
        .filter(Inspection.project_id == project_id)
        .first()
    )
    return _enrich_inspection(insp)


@router.post("/{project_id}/report", response_model=ReportResponse)
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
        project.report.manager_feedback = None
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

    if data.status == "Submitted":
        managers = db.query(User).filter(User.role == "Manager", User.account_status == "Active").all()
        for m in managers:
            notify_user(
                db,
                m.user_id,
                "Report submitted",
                f"Valuation report ready for {project.project_name}",
                "Project",
                project_id,
            )
    log_action(db, user.user_id, "save_report", "report", entity_id=project_id, detail=data.status)
    db.commit()
    db.refresh(report)
    return _enrich_report(report)


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
    return _enrich_report(project.report)


@router.patch("/{project_id}/report/approve", response_model=ReportResponse)
def approve_report(
    project_id: int,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project or not project.report:
        raise HTTPException(status_code=404, detail="No report to approve")
    project.report.status = "Approved"
    project.status = "Completed"
    notify_user(
        db,
        project.valuer_id,
        "Report approved",
        f"Your valuation for {project.project_name} was approved",
        "Project",
        project_id,
    )
    log_action(db, manager.user_id, "approve", "report", entity_id=project.report.report_id)
    db.commit()
    return _enrich_report(project.report)


@router.patch("/{project_id}/report/reject", response_model=ReportResponse)
def reject_report(
    project_id: int,
    data: ReportReject,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project or not project.report:
        raise HTTPException(status_code=404, detail="No report to reject")
    project.report.status = "Rejected"
    project.report.manager_feedback = data.feedback
    notify_user(
        db,
        project.valuer_id,
        "Report needs revision",
        data.feedback,
        "Project",
        project_id,
    )
    log_action(db, manager.user_id, "reject", "report", entity_id=project.report.report_id)
    db.commit()
    return _enrich_report(project.report)


@router.get("/{project_id}/report/pdf")
def download_report_pdf(
    project_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.get(ValuationProject, project_id)
    if not project or not _can_access(project, user):
        raise HTTPException(status_code=403, detail="Access denied")
    if not project.report:
        raise HTTPException(status_code=404, detail="No report")
    pdf = build_report_pdf(project, project.report)
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="valuation_{project_id}.pdf"'},
    )


class EmailReportBody(BaseModel):
    to_email: EmailStr


@router.post("/{project_id}/report/email")
def email_report(
    project_id: int,
    body: EmailReportBody,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    project = db.get(ValuationProject, project_id)
    if not project or not project.report:
        raise HTTPException(status_code=404, detail="No report")
    pdf = build_report_pdf(project, project.report)
    ok = send_report_email_sync(
        str(body.to_email),
        f"Valuation Report — {project.project_name}",
        "Please find the attached valuation report.",
        pdf,
        f"valuation_{project_id}.pdf",
    )
    if not ok:
        raise HTTPException(
            status_code=503,
            detail="SMTP not configured. Set SMTP_HOST in environment.",
        )
    log_action(db, manager.user_id, "email_report", "report", entity_id=project_id)
    db.commit()
    return {"sent": True}
