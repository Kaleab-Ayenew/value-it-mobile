from app.models import User, ValuationProject


def can_access_project(project: ValuationProject, user: User) -> bool:
    if user.role == "Manager":
        return True
    if user.role == "Valuer" and project.valuer_id == user.user_id:
        return True
    if user.role == "SiteInspector" and project.inspector_id == user.user_id:
        return True
    return False
