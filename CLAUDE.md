# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AllOurPhotos is a photo management application for organizing, captioning, and syncing family photos. It supports uploading photos from multiple devices, syncing with Google Photos, editing metadata, creating albums, and scanning/captioning old photos.

## Database Schema

MySQL database with 5 core tables:
- `aopusers` - User accounts and authentication
- `aopsessions` - Active user sessions
- `aopalbums` - Photo album containers
- `aopalbum_items` - Many-to-many join table (albums ↔ snaps)
- `aopsnaps` - Individual photos/videos with metadata (location, captions, rankings, EXIF data)

Schema DDL files are in `ddl/` directory.

## Backend API Architecture

### Authentication
- `GET /ses/{user}/{password}/{source}` - Creates session, returns session ID in "jam" cookie

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

## Git Workflow

- **Main branch**: `master`
