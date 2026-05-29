from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.deps import get_current_user, require_roles
from app.database import get_db
from app.models import MaterialPricing, User
from app.schemas.material import MaterialResponse

router = APIRouter(prefix="/materials", tags=["materials"])


@router.get("", response_model=list[MaterialResponse])
def list_materials(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("Valuer", "Manager")),
):
    return db.query(MaterialPricing).order_by(MaterialPricing.material_name).all()
