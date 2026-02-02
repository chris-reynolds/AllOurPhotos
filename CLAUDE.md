# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AllOurPhotos is a multi-platform photo management application for organizing, captioning, and syncing family photos. The project supports uploading photos from multiple devices, syncing with Google Photos, editing metadata, creating albums, and scanning/captioning old photos.

## Architecture

This is a **multi-stack project** with three main implementations:

### 1. Flutter/Dart Application (`all_our_photos_app/`)
- **Platform**: Cross-platform desktop/mobile app
- **Backend**: FastAPI Python server (`pyserver/`)
- **Database**: MySQL
- **Status**: Original implementation, still in use

### 2. Vue.js Frontend (`pyserver/vue-frontend/`)
- **Framework**: Vue 3 + Vuetify 3 + Vite
- **Backend**: Can use either Python FastAPI or Node/Express backend
- **Current Branch**: `vue_frontend`
- **Status**: Active development

### 3. Node/Express Backend (`backend/`)
- **Purpose**: Migration from FastAPI to Node.js
- **Stack**: Express + Sequelize ORM + MySQL
- **Status**: Complete migration, all functionality preserved from Python backend

## Database Schema

MySQL database with 5 core tables:
- `aopusers` - User accounts and authentication
- `aopsessions` - Active user sessions
- `aopalbums` - Photo album containers
- `aopalbum_items` - Many-to-many join table (albums ↔ snaps)
- `aopsnaps` - Individual photos/videos with metadata (location, captions, rankings, EXIF data)

Schema DDL files are in `ddl/` directory.

## Development Commands

### Vue Frontend Development
```bash
cd pyserver/vue-frontend
npm install
npm run dev          # Development server with hot reload on all interfaces
npm run build        # Production build
```

### Node/Express Backend Development
```bash
cd backend
npm install
npm run dev          # Development mode with nodemon auto-reload
npm start            # Production mode
```

### Python FastAPI Backend
```bash
cd pyserver
pip install -r requirements.txt
# Run with uvicorn (command TBD - check pyserver/src/aopservermain.py)
```

### Flutter App Development
```bash
cd all_our_photos_app
flutter pub get
flutter run
```

## Backend API Architecture

Both Python and Node backends expose identical REST APIs:

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

The Vue frontend stores the session ID as "jam" in localStorage and includes it in requests.

## Configuration Files

### Backend Configuration
- `pyserver/config.json` - Python backend config (DB credentials, photo paths, named SQL queries)
- `backend/.env` - Node backend config (DB credentials, paths, PORT)

### Important Paths
- Photo storage: Configured in backend config (`PHOTOS_DIR` or `photos` key)
- Frontend builds: Can be served statically by backends (`FRONTEND_DIR` in Node, `frontend` in Python)

## Dart Package Structure

The project includes local Dart packages:

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
- **Python backend**: Uses Pillow (PIL) + piexif for image manipulation
- **Node backend**: Uses Sharp + piexifjs for image manipulation
- Both support: cropping, rotation, EXIF metadata reading/writing

### Video Processing
- **Python backend**: Uses ffmpeg-python
- **Node backend**: Uses fluent-ffmpeg

### Geocoding
Both backends support reverse geocoding (lat/long → location names) via external API calls using axios/httpx.

### Vue Frontend Structure
- **Views**: `AlbumListView`, `AlbumDetailView`, `SnapsView`, `SnapDetailView`, `MonthGridView`, `MonthDetailsView`, `LoginView`
- **Components**: `PhotoGrid`, `PhotoTile`, `PhotoGridToolbar`
- **Services**: `snap.service.js`, `album.service.js`, etc. with API abstraction layer
- **Router**: Vue Router with authentication guards (checks localStorage for "jam" session)

### Flutter App Structure
- **Screens**: Home, SignIn, AlbumList, AlbumDetail, SinglePhoto, SingleVideo, MetaEditor
- **Widgets**: PhotoGrid, PhotoTile, SnapGrid, YearGrid, MonthSelector, ImageFilter
- **Providers**: `albumProvider`, `snapProvider` (state management)
- **Utils**: `Config`, `PersistentMap`, `timing`, `ExportPic`

## Common Development Tasks

### Adding a New API Endpoint
1. **Node backend**: Add route in `backend/src/routes/` and import in `backend/src/server.js`
2. **Python backend**: Add route handler in `pyserver/src/aopservermain.py`
3. **Vue frontend**: Add service method in `pyserver/vue-frontend/src/services/`
4. Maintain API consistency across both backends

### Database Changes
1. Update schema in `ddl/Aop10_tables.sql`
2. Update Pydantic models in `pyserver/src/aopmodel.py`
3. Update Sequelize models in `backend/src/models/`
4. Update Dart models in `aopmodel/` package

### Working with the Vue Frontend
- The current branch `vue_frontend` contains active Vue development
- API calls go through service layer that uses `recordedFetch()` for error tracking
- All routes require authentication except `/login` and `/errors`
- Photos are displayed using the `/photos/:path` endpoint from the backend

## Git Workflow

- **Main branch**: `master`
- **Current working branch**: `vue_frontend` (Vue.js frontend development)
- Recent commits focus on month grid and photo grid functionality

## Environment Setup

### Prerequisites
- Node.js (for Vue frontend and Node backend)
- Python 3.11+ (for FastAPI backend)
- MySQL database
- Flutter SDK (for mobile/desktop app)

### Database Setup
1. Create MySQL database
2. Run DDL scripts from `ddl/` directory in order: `Aop10_tables.sql`, `Aop20_session_procs.sql`
3. Configure database credentials in backend config files

### Backend Setup
Choose either Python or Node backend, configure with database credentials and photo storage path.

### Frontend Setup
Either build Flutter app or run Vue development server, configure API_URL to point to chosen backend.
