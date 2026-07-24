---
name: aop-environment-setup
description: First-time dev environment setup for AllOurPhotos - prerequisites, MySQL database creation, DDL script run order, and backend/frontend config. Use when setting up the project from scratch.
---

## Prerequisites
- Python 3.11+ (for FastAPI backend)
- MySQL database
- Flutter SDK (for mobile/desktop app)

## Database Setup
1. Create MySQL database
2. Run DDL scripts from `ddl/` directory in order: `Aop10_tables.sql`, `Aop20_session_procs.sql`
3. Configure database credentials in `pyserver/config.json`

## Backend Setup
Configure `pyserver/config.json` with database credentials and photo storage path.

## Frontend Setup
Build Flutter app and configure API URL to point to the Python backend.
