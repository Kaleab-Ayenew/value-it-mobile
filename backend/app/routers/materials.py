import csv
import io
from decimal import Decimal

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.auth.deps import get_current_user, require_roles
from app.database import get_db
from app.models import MaterialPricing, User
from app.schemas.material import MaterialCreate, MaterialResponse, MaterialUpdate
from app.services.audit import log_action

router = APIRouter(prefix="/materials", tags=["materials"])


@router.get("", response_model=list[MaterialResponse])
def list_materials(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return db.query(MaterialPricing).order_by(MaterialPricing.material_name).all()


@router.post("", response_model=MaterialResponse, status_code=201)
def create_material(
    data: MaterialCreate,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    m = MaterialPricing(**data.model_dump())
    db.add(m)
    log_action(db, manager.user_id, "create", "material", detail=data.material_name)
    db.commit()
    db.refresh(m)
    return m


@router.patch("/{material_id}", response_model=MaterialResponse)
def update_material(
    material_id: int,
    data: MaterialUpdate,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    m = db.get(MaterialPricing, material_id)
    if not m:
        raise HTTPException(status_code=404, detail="Not found")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(m, k, v)
    log_action(db, manager.user_id, "update", "material", entity_id=material_id)
    db.commit()
    db.refresh(m)
    return m


@router.delete("/{material_id}", status_code=204)
def delete_material(
    material_id: int,
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    m = db.get(MaterialPricing, material_id)
    if not m:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(m)
    log_action(db, manager.user_id, "delete", "material", entity_id=material_id)
    db.commit()


@router.post("/import")
async def import_csv(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    manager: User = Depends(require_roles("Manager")),
):
    content = (await file.read()).decode("utf-8")
    reader = csv.DictReader(io.StringIO(content))
    count = 0
    for row in reader:
        name = row.get("material_name") or row.get("name")
        if not name:
            continue
        unit = row.get("unit", "unit")
        price = Decimal(str(row.get("unit_price") or row.get("price") or "0"))
        source = row.get("price_source") or row.get("source")
        db.add(
            MaterialPricing(
                material_name=name.strip(),
                unit=unit.strip(),
                unit_price=price,
                price_source=source,
            )
        )
        count += 1
    log_action(db, manager.user_id, "import", "material", detail=f"{count} rows")
    db.commit()
    return {"imported": count}
