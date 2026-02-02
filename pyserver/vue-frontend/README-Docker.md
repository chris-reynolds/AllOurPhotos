# Vue Frontend - Docker Setup

This directory contains a containerized Vue.js application built with Vite for production deployment.

## Quick Start

### Production Mode
```bash
# Build and run production container
docker-compose up

# Or run in detached mode
docker-compose up -d
```

The production server will be available at `http://localhost:3000`

### Development Mode
For development, run the Vite dev server locally (no Docker needed):
```bash
npm run dev
```

## How It Works

### Multi-Stage Dockerfile Explained

The Dockerfile contains 2 stages:

1. **Build Stage** (`build`): 
   - Installs dependencies and builds the production assets
   - Creates the `dist/` folder with optimized files
   - This stage is only used to create the build artifacts

2. **Production Stage** (`production`):
   - Uses the `serve` package to serve static files
   - Copies only the built `dist/` folder from the build stage
   - Runs on port 3000
   - Lightweight and optimized for production

## Docker Commands

### Building and Running

```bash
# Build and run
docker-compose up

# Build and run in background
docker-compose up -d

# Build only
docker-compose build

# Stop
docker-compose down

# Rebuild and start
docker-compose up --build

# View logs
docker-compose logs
```

### Direct Docker Commands

```bash
# Build production image
docker build -t vue-frontend:prod .

# Run production container
docker run -p 3000:3000 vue-frontend:prod
```

### Using Docker Compose

```bash
# Start services
docker-compose up

# Start specific service
docker-compose up vue-frontend-dev

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# Rebuild and start
docker-compose up --build

# View logs
docker-compose logs vue-frontend-dev
```

## Architecture

### Simplified Build
- **Build Stage**: Compiles the Vue/Vite app into static files
- **Production Stage**: Serves static files with `serve` package (port 3000)

### Production Features
- Lightweight static file server
- No nginx dependency (integrates with your existing nginx)
- SPA routing support via `serve -s`
- Runs on port 3000

### Development
For development, simply run locally:
```bash
npm run dev  # Runs on port 5173 with hot reload
```

## Environment Variables

You can override environment variables in `docker-compose.yml` or pass them directly:

```bash
docker run -e NODE_ENV=production -p 80:80 vue-frontend:prod
```

## Troubleshooting

### Port Conflicts
If ports 5173 or 80 are already in use, modify the port mappings in `docker-compose.yml`:

```yaml
ports:
  - "3000:5173"  # Use port 3000 instead of 5173
```

### Volume Issues on Windows
If you're on Windows and experiencing issues with volume mounting, make sure Docker Desktop is configured to share the drive containing your project.

### Building Issues
If the build fails, try:

```bash
# Clean up and rebuild
docker-compose down
docker system prune -f
docker-compose up --build
```

## Production Deployment

For production deployment, you might want to:

1. Use a reverse proxy (like Traefik or nginx) in front of the container
2. Set up SSL/TLS certificates
3. Configure environment-specific variables
4. Set up health checks and monitoring

Example production docker-compose with additional services:

```yaml
version: '3.8'
services:
  vue-frontend:
    build:
      context: .
      target: production
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.vue-frontend.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.vue-frontend.tls.certresolver=letsencrypt"
```