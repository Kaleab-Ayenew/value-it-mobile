# ValueIt — Flutter + FastAPI

Cost-based property valuation management (mobile-first, Flutter web–ready) backed by FastAPI, PostgreSQL, and MinIO object storage.

## Prerequisites

- Flutter 3.x
- Docker
- Python 3.10+

## Backend

```bash
cd backend
docker compose up -d          # PostgreSQL, MinIO, bucket init
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env        # MinIO + optional SMTP
.venv/bin/alembic upgrade head
.venv/bin/python scripts/seed.py
.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs  
MinIO console: http://localhost:9001 (minioadmin / minioadmin)

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

# Physical device (USB)
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```
