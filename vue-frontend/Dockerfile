# Multi-stage Docker build for Vue/Vite application

# Stage 1: Build stage - builds the production assets
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# Install all dependencies (needed for build)
RUN npm ci

# Copy source code
COPY . .

# Build the production bundle
RUN npm run build

# Stage 2: Production stage - serves the built static files
FROM node:18-alpine AS production

# Install serve globally for serving static files
RUN npm install -g serve

WORKDIR /app

# Copy only the built files from the build stage
COPY --from=build /app/dist ./dist

# Expose port 3000 for the production server
EXPOSE 3000

# Serve the static files with SPA support
CMD ["serve", "-s", "dist", "-l", "3000"]