# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AllOurPhotos is a photo management application for organizing, captioning, and syncing family photos. It supports uploading photos from multiple devices, syncing with Google Photos, editing metadata, creating albums, and scanning/captioning old photos.

## Architecture

### Flutter/Dart Application (`all_our_photos_app/`)
- **Platform**: Cross-platform desktop/mobile app
- **Backend**: FastAPI Python server (`pyserver/`)
- **Database**: MySQL

### Python FastAPI Backend (`pyserver/`)
- **Framework**: FastAPI + Pillow + piexif + ffmpeg-python
- **Config**: `pyserver/config.json` (DB credentials, photo paths, named SQL queries)

## Database Schema

MySQL database with 5 core tables:
- `aopusers` - User accounts and authentication
- `aopsessions` - Active user sessions
- `aopalbums` - Photo album containers
- `aopalbum_items` - Many-to-many join table (albums ↔ snaps)
- `aopsnaps` - Individual photos/videos with metadata (location, captions, rankings, EXIF data)

Schema DDL files are in `ddl/` directory.

## Development Commands

### Python FastAPI Backend
```bash
cd pyserver
pip install -r requirements.txt
# Run with uvicorn (see pyserver/src/aopservermain.py)
```

### Flutter App Development
```bash
cd all_our_photos_app
flutter pub get
flutter run
```

## Backend API Architecture

### Authentication
- `GET /ses/{user}/{password}/{source}` - Creates session, returns session ID in "jam" cookie

### CRUD Resources
Standard CRUD operations on `/albums`, `/snaps`, `/sessions`, `/users`, `/album_items`:
- `POST /` - Create with JSON body
- `GET /:id` - Get by ID
- `GET /` - List with query params: `where`, `orderby`, `limit`, `offset`
- `PUT /` - Update with JSON body
- `DELETE /:id` - Delete by ID

### Custom Endpoints
- `GET /version` - Server version info
- `GET /find/:key` - Execute named queries from config.json
- `GET /crop/:id/:left/:top/:right/:bottom` - Crop image
- `GET /rotate/:angle/:path` - Rotate image
- `POST /upload2/:modified/:filename/:sourceDevice` - Upload photo/video
- `GET /photos/:path` - Serve photo files
- `PUT /photos/:path` - Update photo files

### Authentication Pattern
APIs use cookie/header-based auth with "Preserve" cookie containing JSON:
```json
{"jam": "<session_id>"}
```

## Configuration Files

- `pyserver/config.json` - Backend config (DB credentials, photo paths, named SQL queries)
- Photo storage path configured via `photos` key in config.json
- Frontend build served statically via `frontend` key in config.json

## Dart Package Structure

### `aopmodel/`
Data models shared between Flutter apps (corresponds to database tables)

### `aopcommon/`
Shared utilities for All Our Photos Dart apps:
- Global objects: `config`, `log`
- List support: `Selection<T>` mixin, `ListProvider<T>` abstract class
- Date utilities: `addMonths()`, `daysInMonth()`, `dbDate()`, `formatDate()`, `parseDMY()`, `dateTimeFromExif()`
- String utilities: `left()`, `right()`

### `aopsync/`
Syncing functionality (check package for details)

### `shrink2album/`
Command-line tool for album operations

## Key Implementation Details

### Image Processing
- Uses Pillow (PIL) + piexif for image manipulation (cropping, rotation, EXIF read/write)

### Video Processing
- Uses ffmpeg-python

### Geocoding
- Reverse geocoding (lat/long → location names) via external API calls using httpx

### Flutter App Structure
- **Screens**: Home, SignIn, AlbumList, AlbumDetail, SinglePhoto, SingleVideo, MetaEditor
- **Widgets**: PhotoGrid, PhotoTile, SnapGrid, YearGrid, MonthSelector, ImageFilter
- **Providers**: `albumProvider`, `snapProvider` (state management)
- **Utils**: `Config`, `PersistentMap`, `timing`, `ExportPic`

### Rotation Handling
- Rotation degrees stored in `aopsnaps.degrees` database field
- Flutter app requests rotated images via `/rotate/{degrees}/{path}` endpoint
- Backend rotates and crops images dynamically on request

## Common Development Tasks

### Adding a New API Endpoint
1. Add route handler in `pyserver/src/aopservermain.py`
2. Add corresponding method in the Flutter app's service/model layer

### Database Changes
1. Update schema in `ddl/Aop10_tables.sql`
2. Update Pydantic models in `pyserver/src/aopmodel.py`
3. Update Dart models in `aopmodel/` package

## Git Workflow

- **Main branch**: `master`

## Environment Setup

### Prerequisites
- Python 3.11+ (for FastAPI backend)
- MySQL database
- Flutter SDK (for mobile/desktop app)

### Database Setup
1. Create MySQL database
2. Run DDL scripts from `ddl/` directory in order: `Aop10_tables.sql`, `Aop20_session_procs.sql`
3. Configure database credentials in `pyserver/config.json`

### Backend Setup
Configure `pyserver/config.json` with database credentials and photo storage path.

### Frontend Setup
Build Flutter app and configure API URL to point to the Python backend.
