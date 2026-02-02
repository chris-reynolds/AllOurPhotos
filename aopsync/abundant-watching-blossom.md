# AopSync Enhancement Plan

## Overview
Improve aopsync reliability, test coverage, iOS support, and add server health monitoring. Keep current HTTP upload approach with manual trigger.

## Phase 1: Testing Foundation & Testability Refactoring

### 1a. Add test dependencies (`pubspec.yaml`)
- Add `mockito: ^5.4.0` and `build_runner` to dev_dependencies

### 1b. Extract interfaces from `SyncDriver.dart` for testability
Currently SyncDriver directly calls file system, HTTP, and model statics. Extract:
- **`FileScanner`** (`lib/services/file_scanner.dart`) - wraps `Directory.list()` logic
- **`DuplicateChecker`** (`lib/services/duplicate_checker.dart`) - wraps `AopSnap.nameSameDayExists()`
- **`FileUploader`** (`lib/services/file_uploader.dart`) - wraps multipart POST upload

Inject into `SyncDriver` constructor with production defaults so `scHome.dart` changes minimally.

### 1c. Write unit tests
- `test/sync_driver_test.dart` - file filtering, date extraction from filenames, upload flow with mocks
- `test/file_fate_test.dart` - fate tracking and summary
- `test/config_test.dart` - load/save/dirty flag with mocked SharedPreferences
- `test/authentication_state_test.dart` - state constructors

### 1d. Code cleanup in `SyncDriver.dart`
- Remove commented-out code, move `fateList` from global to instance-scoped

## Phase 2: Reliability Enhancements

### 2a. Retry logic in `FileUploader`
- Max 3 retries with exponential backoff (2s, 4s, 8s)
- Only retry on network errors and 5xx; stop on 4xx/auth errors
- Richer `UploadResult` type with error classification

### 2b. Error categorization (`lib/services/error_classifier.dart`)
- `network` / `serverError` / `authExpired` / `clientError` / `duplicate`
- On `authExpired`, stop batch and signal UI to re-login

### 2c. Connection pre-check
- Call `/version` endpoint before starting sync
- Show clear error message if server unreachable

### 2d. Persistent upload queue (`lib/services/upload_queue.dart`)
- Persist pending file list to SharedPreferences
- On restart, offer to resume incomplete sync

## Phase 3: iOS Support

### 3a. Add `photo_manager: ^3.0.0` to `pubspec.yaml`

### 3b. Rewrite `IosGallery.dart`
- Implement using photo_manager v3 API (currently all commented out)
- `loadFrom()` with date filtering, `operator[]` with file byte access

### 3c. Platform-aware scanning in `scHome.dart`
- iOS: use `IosGallery`; Android/Windows: use file system `SyncDriver`

### 3d. iOS permission handling in `scLaunchWithLogin.dart`
- Add `PhotoManager.requestPermissionExtend()` for iOS path

## Phase 4: Server Health Monitoring (Python/FastAPI backend in `pyserver/`)

### 4a. Health endpoint in `pyserver/src/aopservermain.py`
- Add `GET /health` route - returns uptime, DB connection status, photo dir accessibility (no auth required)
- Uses existing `connection_pool` to test DB with `SELECT 1`
- Checks photo directory from `config.json`

### 4b. Sync error logging
- Log upload failures to a `sync_errors` table or structured log file
- Add `GET /admin/sync-errors?since=<datetime>` admin endpoint

### 4c. Email alerts
- Add email alerting using Python `smtplib` / `email` stdlib modules
- Use `apscheduler` or a simple background thread to check periodically
- Alert if no sync activity for N hours or error rate exceeds threshold
- SMTP config added to `config.json`

### 4d. Client health integration
- After login, call `/health` and display server status in `scHome.dart`

## Phase 5: Integration Tests
- `test/integration/upload_flow_test.dart` - test HTTP server mimicking `/upload2`, full scan-upload flow, retry on 500, auth expiry handling

## Key Files to Modify
- `aopsync/lib/SyncDriver.dart` - refactor for testability, extract interfaces
- `aopsync/lib/IosGallery.dart` - rewrite with photo_manager
- `aopsync/lib/screens/scHome.dart` - health check, platform detection, queue resume
- `aopsync/lib/fileFate.dart` - instance-scope fateList
- `aopsync/pubspec.yaml` - new dependencies
- `pyserver/src/aopservermain.py` - new health endpoint and sync error logging

## Verification
- Run `flutter test` after each phase to confirm tests pass
- Test Android build: `flutter build apk --debug`
- Test Windows build: `flutter build windows`
- Test iOS build: `flutter build ios --simulator` (requires Mac)
- Manual test: run sync against dev server, verify retry on simulated failures
- Verify `/health` endpoint with `curl http://localhost:8000/health`
