# ValueIt — Flutter MVP

Cost-based property valuation management (mobile-first, Flutter web–ready) backed by FastAPI + PostgreSQL.

## Prerequisites

- Flutter 3.x
- Docker
- Python 3.10+

## Backend

```bash
cd backend
docker compose up -d
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/alembic upgrade head
.venv/bin/python scripts/seed.py
.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

### Seed accounts

| Role | Email | Password |
|------|-------|----------|
| Manager | manager@valueit.com | manager123 |
| Valuer | valuer@valueit.com | valuer123 |
| Inspector | inspector@valueit.com | inspector123 |

## Flutter app

```bash
cd valueit_app
flutter pub get

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Linux desktop
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8000
```

## MVP workflow

1. **Manager** — Create project → assign valuer & inspector → approve submitted report.
2. **Inspector** — Submit inspection data and upload site photos.
3. **Valuer** — Review inspection, add material line items, submit valuation report.

## Project structure

```
mobile_project/
├── backend/          # FastAPI + PostgreSQL
└── valueit_app/      # Flutter (Android, iOS, Web, Desktop)
```
