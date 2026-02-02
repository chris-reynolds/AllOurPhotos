import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import sequelize from './config/database.js';

// Import routes
import albumRoutes from './routes/albums.js';
import snapRoutes from './routes/snaps.js';
import sessionRoutes from './routes/sessions.js';
import userRoutes from './routes/users.js';
import albumItemRoutes from './routes/albumItems.js';
import customRoutes from './routes/custom.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 8000;

// Middleware
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);

    // Allow localhost and 127.0.0.1 on any port
    const allowedOrigins = [
      /^http:\/\/localhost(:\d+)?$/,
      /^http:\/\/127\.0\.0\.1(:\d+)?$/,
      /^https:\/\/localhost(:\d+)?$/,
      /^https:\/\/127\.0\.0\.1(:\d+)?$/
    ];

    const isAllowed = allowedOrigins.some(pattern => pattern.test(origin));

    if (isAllowed) {
      callback(null, true);
    } else {
      console.log('CORS blocked origin:', origin);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Preserve']
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// API Routes
app.use('/albums', albumRoutes);
app.use('/snaps', snapRoutes);
app.use('/sessions', sessionRoutes);
app.use('/users', userRoutes);
app.use('/album_items', albumItemRoutes);

// Custom routes (version, ses, find, crop, rotate, upload, photos)
app.use('/', customRoutes);

// Serve static frontend files
if (process.env.FRONTEND_DIR) {
  app.use(express.static(process.env.FRONTEND_DIR));

  // Fallback to index.html for SPA routes
  app.get('*', (req, res) => {
    res.sendFile(path.join(process.env.FRONTEND_DIR, 'index.html'));
  });
}

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    detail: err.message || 'Internal Server Error'
  });
});

// Test database connection and start server
async function startServer() {
  try {
    await sequelize.authenticate();
    console.log('Database connection has been established successfully.');

    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
}

startServer();
