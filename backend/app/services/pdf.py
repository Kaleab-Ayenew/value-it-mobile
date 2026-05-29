import json
from io import BytesIO

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.pdfgen import canvas

from app.models import ValuationProject, ValuationReport


def build_report_pdf(project: ValuationProject, report: ValuationReport) -> bytes:
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    y = height - 2 * cm

    c.setFont("Helvetica-Bold", 16)
    c.drawString(2 * cm, y, "ValueIt Valuation Report")
    y -= 1 * cm
    c.setFont("Helvetica", 11)
    c.drawString(2 * cm, y, f"Project: {project.project_name}")
    y -= 0.6 * cm
    if project.location:
        c.drawString(2 * cm, y, f"Location: {project.location}")
        y -= 0.6 * cm
    c.drawString(2 * cm, y, f"Status: {report.status}")
    y -= 0.8 * cm
    c.drawString(2 * cm, y, f"Calculated value: {report.calculated_value or 0:,.2f} ETB")
    y -= 1.2 * cm

    c.setFont("Helvetica-Bold", 12)
    c.drawString(2 * cm, y, "Line items")
    y -= 0.7 * cm
    c.setFont("Helvetica", 10)

    try:
        data = json.loads(report.report_content or "{}")
        items = data.get("line_items", [])
        notes = data.get("notes")
    except json.JSONDecodeError:
        items = []
        notes = report.report_content

    for item in items:
        if y < 3 * cm:
            c.showPage()
            y = height - 2 * cm
        line = f"{item.get('material_name')} — {item.get('quantity')} {item.get('unit')} @ {item.get('unit_price')} = {item.get('total')}"
        c.drawString(2 * cm, y, line[:95])
        y -= 0.5 * cm

    if notes:
        y -= 0.5 * cm
        c.setFont("Helvetica-Bold", 11)
        c.drawString(2 * cm, y, "Notes")
        y -= 0.6 * cm
        c.setFont("Helvetica", 10)
        for chunk in _wrap(notes, 90):
            if y < 2 * cm:
                c.showPage()
                y = height - 2 * cm
            c.drawString(2 * cm, y, chunk)
            y -= 0.5 * cm

    if report.manager_feedback:
        y -= 0.5 * cm
        c.setFont("Helvetica-Bold", 11)
        c.drawString(2 * cm, y, "Manager feedback")
        y -= 0.6 * cm
        c.setFont("Helvetica", 10)
        for chunk in _wrap(report.manager_feedback, 90):
            c.drawString(2 * cm, y, chunk)
            y -= 0.5 * cm

    c.save()
    buffer.seek(0)
    return buffer.read()


def _wrap(text: str, width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for w in words:
        test = " ".join(current + [w])
        if len(test) <= width:
            current.append(w)
        else:
            if current:
                lines.append(" ".join(current))
            current = [w]
    if current:
        lines.append(" ".join(current))
    return lines or [""]
