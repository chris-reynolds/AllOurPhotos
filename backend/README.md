# AllOurPhotos Backend

Node/Express backend for the AllOurPhotos application.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

3. Update the `.env` file with your database credentials and paths.

## Database Configuration

The backend expects a MySQL database with the following tables:
- `aopusers` - User accounts
- `aopsessions` - User sessions
- `aopalbums` - Photo albums
- `aopalbum_items` - Many-to-many relationship between albums and snaps
- `aopsnaps` - Individual photos/videos

## Running the Server

Development mode with auto-reload:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

The server will start on port 8000 by default (configurable via PORT environment variable).

## API Endpoints

### Authentication
- `GET /ses/:user/:password/:source` - Create session (login)

### CRUD Operations
All resources support standard CRUD operations:

**Albums** (`/albums`)
- `POST /` - Create album
- `GET /:id` - Get single album
- `GET /` - Get albums (with where, orderby, limit, offset query params)
- `PUT /` - Update album
- `DELETE /:id` - Delete album

**Snaps** (`/snaps`)
- Same CRUD operations as albums

**Sessions** (`/sessions`)
- Same CRUD operations as albums

**Users** (`/users`)
- Same CRUD operations as albums

**Album Items** (`/album_items`)
- Same CRUD operations as albums

### Custom Routes
- `GET /version` - Get server version
- `GET /find/:key` - Execute custom SQL queries from config.json
- `GET /crop/:id/:left/:top/:right/:bottom` - Crop an image
- `GET /rotate/:angle/:path` - Rotate an image
- `POST /upload2/:modified/:filename/:sourceDevice` - Upload an image
- `GET /photos/:path` - Serve photo files
- `PUT /photos/:path` - Update photo files

## Authentication

The API uses cookie/header-based authentication with a "Preserve" cookie/header containing session data in JSON format:
```json
{
  "jam": "<session_id>"
}
```

## Environment Variables

- `DB_HOST` - MySQL host
- `DB_USER` - MySQL user
- `DB_PASSWORD` - MySQL password
- `DB_NAME` - MySQL database name
- `DB_PORT` - MySQL port (default: 3306)
- `PHOTOS_DIR` - Root directory for photo storage
- `FRONTEND_DIR` - Directory for frontend static files
- `PORT` - Server port (default: 8000)
- `NODE_ENV` - Environment (development/production)

## Dependencies

- **express** - Web framework
- **sequelize** - ORM for MySQL
- **mysql2** - MySQL driver
- **sharp** - Image processing
- **fluent-ffmpeg** - Video processing
- **axios** - HTTP client for geocoding
- **multer** - File upload handling
- **cors** - CORS middleware
- **cookie-parser** - Cookie parsing
- **dotenv** - Environment variable management

## Migration from FastAPI

This backend is a complete migration from the original FastAPI (Python) backend. All functionality has been preserved:

- Database models using Sequelize instead of Pydantic
- Image processing using Sharp instead of Pillow
- Video processing using fluent-ffmpeg instead of python-ffmpeg
- All API endpoints maintain the same interface
- Authentication mechanism preserved
- Geocoding functionality maintained
