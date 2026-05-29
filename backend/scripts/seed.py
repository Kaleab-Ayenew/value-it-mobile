"""Seed manager account and material pricing."""
import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.auth.security import hash_password
from app.database import SessionLocal
from app.models import MaterialPricing, User

MATERIALS = [
    ("Cement (50kg bag)", "bag", 650.00),
    ("Reinforcement Steel (12mm)", "kg", 95.00),
    ("Sand (river)", "m³", 1200.00),
    ("Gravel", "m³", 1400.00),
    ("Hollow Concrete Block", "piece", 28.00),
    ("Roofing Sheet (CGI)", "sheet", 1850.00),
    ("Paint (exterior, 20L)", "bucket", 3200.00),
    ("Ceramic Floor Tile", "m²", 450.00),
    ("Plywood (12mm)", "sheet", 2100.00),
    ("Electrical Wire (2.5mm²)", "m", 85.00),
]

SOURCE = "AACDWB Quarterly Direct Cost Report (sample)"


def main():
    db = SessionLocal()
    try:
        if not db.query(User).filter(User.email == "manager@valueit.com").first():
            db.add(
                User(
                    full_name="Demo Manager",
                    email="manager@valueit.com",
                    password_hash=hash_password("manager123"),
                    role="Manager",
                    phone_number="+251911000000",
                    account_status="Active",
                )
            )
        if not db.query(User).filter(User.email == "valuer@valueit.com").first():
            db.add(
                User(
                    full_name="Demo Valuer",
                    email="valuer@valueit.com",
                    password_hash=hash_password("valuer123"),
                    role="Valuer",
                    phone_number="+251911000001",
                    account_status="Active",
                )
            )
        if not db.query(User).filter(User.email == "inspector@valueit.com").first():
            db.add(
                User(
                    full_name="Demo Inspector",
                    email="inspector@valueit.com",
                    password_hash=hash_password("inspector123"),
                    role="SiteInspector",
                    phone_number="+251911000002",
                    account_status="Active",
                )
            )
        if db.query(MaterialPricing).count() == 0:
            for name, unit, price in MATERIALS:
                db.add(
                    MaterialPricing(
                        material_name=name,
                        unit=unit,
                        unit_price=Decimal(str(price)),
                        price_source=SOURCE,
                    )
                )
        db.commit()
        print("Seed complete.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
