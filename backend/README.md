# Cohab backend

FastAPI + PostgreSQL backend for the Cohab iOS app.

## Stack

- **FastAPI** — async REST API with auto-generated OpenAPI docs at `/docs`
- **SQLAlchemy 2.0** async — ORM with `asyncpg` driver
- **PostgreSQL 16** — via Docker for local dev
- **JWT auth** — `python-jose`, 30-day tokens
- **bcrypt** — password hashing

## Quick start

```bash
# 1. Start Postgres
docker compose up -d

# 2. Create virtualenv and install
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 3. Copy env
cp .env.example .env

# 4. Run (tables auto-created on startup)
uvicorn main:app --reload
```

API docs: http://localhost:8000/docs

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/register | Create account, returns JWT |
| POST | /auth/token | Login (OAuth2 form), returns JWT |
| GET | /households/me | Get current user's household |
| POST | /households | Create household |
| PUT | /households/{id} | Update household |
| GET | /households/{id}/expenses | List expenses |
| POST | /households/{id}/expenses | Add expense |
| POST | /assets | Create asset |
| PUT | /assets/{id} | Update asset |
| DELETE | /assets/{id} | Delete asset |
| GET | /assets/{id}/contributions | List contributions |
| POST | /assets/{id}/contributions | Add contribution |
| DELETE | /assets/{id}/contributions/{cid} | Delete contribution |

## Design notes

- One household per user (enforced at DB layer)
- All endpoints require Bearer JWT auth except /auth/*
- Settlement math lives in the iOS app — the backend is a sync/persistence layer only
- Tables are created automatically on startup via SQLAlchemy metadata; use Alembic for production migrations
