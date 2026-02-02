# AllOurPhotos Frontend

Modern Vue 3 + Vuetify 3 frontend with improved state management, logging, and error handling.

## Architecture Overview

### Key Improvements

1. **Proper State Management with Pinia**
   - Centralized stores for auth, UI, logs, snaps, and albums
   - Reactive state with composition API
   - Type-safe actions and getters

2. **Structured Logging System**
   - Centralized logger utility with multiple log levels
   - In-memory log storage with configurable size
   - Log persistence and download capabilities
   - Integration with Pinia store for reactive access

3. **Enhanced Error Handling**
   - Axios interceptors for request/response logging
   - Automatic error detection and logging
   - Global error dialog and snackbar notifications
   - Network error detection
   - Automatic session cleanup on 401 errors

## Project Structure

```
frontend/
├── src/
│   ├── components/       # Reusable Vue components
│   │   └── LogList.vue  # Log display component
│   ├── stores/          # Pinia stores
│   │   ├── auth.js      # Authentication state
│   │   ├── ui.js        # UI state (loading, snackbars, errors)
│   │   ├── logs.js      # Application logs
│   │   ├── snaps.js     # Photo/video data
│   │   └── albums.js    # Album data
│   ├── services/        # API services
│   │   └── api.js       # Enhanced axios client with interceptors
│   ├── utils/           # Utilities
│   │   └── logger.js    # Centralized logging utility
│   ├── views/           # Page components
│   │   ├── LoginView.vue
│   │   ├── LogsView.vue
│   │   ├── MonthGridView.vue
│   │   ├── MonthDetailsView.vue
│   │   ├── SnapDetailView.vue
│   │   ├── AlbumListView.vue
│   │   └── AlbumDetailView.vue
│   ├── router/          # Vue Router configuration
│   │   └── index.js
│   ├── plugins/         # Plugin configurations
│   │   └── vuetify.js
│   ├── App.vue          # Root component
│   └── main.js          # Application entry point
├── public/              # Static assets
├── index.html
├── vite.config.js       # Vite configuration
└── package.json
```

## State Management

### Stores

#### Auth Store (`stores/auth.js`)
Manages user authentication and session:
- `login(user, password, source)` - Authenticate user
- `logout()` - Clear session
- `checkSession()` - Restore session from localStorage
- State: `userId`, `username`, `sessionId`, `isAuthenticated`

#### UI Store (`stores/ui.js`)
Manages global UI state:
- `startLoading(message)` / `stopLoading()` - Loading overlay
- `showSnackbar(message, color, timeout)` - Toast notifications
- `showSuccess/Error/Warning/Info(message)` - Convenience methods
- `setError(error)` / `clearError()` - Error dialog

#### Logs Store (`stores/logs.js`)
Centralized log storage:
- Syncs with logger utility
- Provides filtered views (errors, warnings, info)
- Export and download capabilities
- Real-time log counts

#### Snaps Store (`stores/snaps.js`)
Photo/video management:
- CRUD operations for snaps
- Client-side filtering
- URL generation for thumbnails and full images

#### Albums Store (`stores/albums.js`)
Album management:
- CRUD operations for albums
- Album item management
- Sorted album lists

## Logging System

### Logger Utility (`utils/logger.js`)

The logger provides structured logging with multiple levels:

```javascript
import { logger, LOG_LEVELS } from '@/utils/logger'

// Log levels: DEBUG, INFO, WARN, ERROR
logger.debug('Debug message', { data }, 'CONTEXT')
logger.info('Info message', { data }, 'CONTEXT')
logger.warn('Warning message', { data }, 'CONTEXT')
logger.error('Error message', { data }, 'CONTEXT')
```

**Features:**
- Timestamp on every log entry
- Optional data object and context string
- Stack traces for errors
- In-memory storage (max 1000 entries)
- Export logs as JSON
- Environment-aware (DEBUG level in dev, INFO in prod)

### Integration with Stores

The logger integrates with the Logs store to provide reactive access:

```javascript
import { useLogsStore } from '@/stores/logs'

const logsStore = useLogsStore()
console.log(logsStore.errorCount)  // Reactive count of errors
logsStore.downloadLogs()            // Download all logs
```

## Error Handling

### API Service (`services/api.js`)

Enhanced axios client with:

**Request Interceptor:**
- Adds authentication headers automatically
- Logs all outgoing requests
- Tracks request timing

**Response Interceptor:**
- Logs all responses with timing
- Enhanced error handling:
  - Network error detection
  - HTTP status code handling
  - Automatic session cleanup on 401
  - Structured error objects

**Usage:**
```javascript
import { api } from '@/services/api'

try {
  const data = await api.get('/snaps/', { where: '1=1', limit: 100 })
  const snap = await api.post('/snaps', snapData)
  await api.put('/snaps', updatedSnap)
  await api.delete(`/snaps/${id}`)
} catch (error) {
  // Error automatically logged and enhanced
  console.log(error.status)      // HTTP status code
  console.log(error.data)        // Response data
  console.log(error.isApiError)  // true
}
```

### Global Error Handling

**App-level error handler:**
```javascript
app.config.errorHandler = (err, instance, info) => {
  logger.error('Global error', { message, stack, info }, 'APP')
}
```

**Component-level:**
```javascript
try {
  await someOperation()
} catch (error) {
  // Automatically logged by API interceptor
  // Show user-friendly message
  uiStore.showError('Operation failed')
}
```

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

Server will start on http://localhost:5173

## Build for Production

```bash
npm run build
```

## Environment Variables

Create a `.env` file:

```env
VITE_API_URL=http://localhost:8000
```

If not provided, defaults to same host on port 8000.

## Key Features

### Authentication
- Session-based authentication
- Automatic session restoration
- Protected routes
- Automatic redirect to login

### Logging
- Centralized logging utility
- Multiple log levels
- In-memory storage
- Log filtering by level
- Export and download logs
- Real-time error counts

### Error Management
- Request/response logging
- Automatic error detection
- User-friendly error messages
- Global error dialog
- Toast notifications
- Network error handling

### Loading States
- Global loading overlay
- Per-operation loading
- Stacked loading tasks

## Navigation

- **/** - Month Grid (home)
- **/month/:yearMonth** - Month details
- **/snap/:id** - Photo detail
- **/albums** - Album list
- **/album/:id** - Album detail
- **/logs** - Application logs
- **/login** - Login page

## Best Practices

### Using Stores

```javascript
// In components
import { useAuthStore } from '@/stores/auth'
import { useUIStore } from '@/stores/ui'

const authStore = useAuthStore()
const uiStore = useUIStore()

// Access reactive state
console.log(authStore.username)
console.log(uiStore.isLoading)

// Call actions
await authStore.login(user, password)
uiStore.showSuccess('Operation complete')
```

### Logging

```javascript
import { logger } from '@/utils/logger'

// Always include context
logger.info('User logged in', { userId }, 'AUTH')
logger.error('API call failed', error, 'SNAP_COMPONENT')
```

### Error Handling

```javascript
try {
  uiStore.startLoading('Saving photo...')
  const snap = await snapsStore.createSnap(snapData)
  uiStore.showSuccess('Photo saved')
} catch (error) {
  // Error already logged by API interceptor
  // Just show user-friendly message
  uiStore.showError('Failed to save photo')
} finally {
  uiStore.stopLoading()
}
```

## Migration from Old Frontend

The new frontend improves upon the old version in several ways:

1. **State Management**: Proper Pinia stores instead of reactive objects
2. **Logging**: Structured logging system with levels and persistence
3. **Error Handling**: Centralized error handling with interceptors
4. **API Client**: Axios with request/response logging and timing
5. **UI Feedback**: Consistent loading states and notifications
6. **Type Safety**: Better JSDoc annotations for IDE support
7. **Architecture**: Clear separation of concerns

## Future Enhancements

- [ ] Offline support with service workers
- [ ] Image lazy loading and virtual scrolling
- [ ] Real-time updates with WebSockets
- [ ] Advanced filtering and search
- [ ] Batch operations
- [ ] Photo editing capabilities
- [ ] Export features
