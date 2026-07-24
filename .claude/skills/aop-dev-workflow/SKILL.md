---
name: aop-dev-workflow
description: Checklists for common AllOurPhotos development tasks - adding a new API endpoint, or making a database schema change. Use when the user asks to add an endpoint or change the DB schema.
---

## Adding a New API Endpoint
1. Add route handler in `pyserver/src/aopservermain.py`
2. Add corresponding method in the Flutter app's service/model layer

## Database Changes
1. Update schema in `ddl/Aop10_tables.sql`
2. Update Pydantic models in `pyserver/src/aopmodel.py`
3. Update Dart models in `aopmodel/` package
