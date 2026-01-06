/**
 * Minecraft Church Verification System API Server
 * Main entry point for the API
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const db = require('./db');

// Import routes
const codesRouter = require('./routes/codes');
const requestsRouter = require('./routes/requests');
const grantsRouter = require('./routes/grants');
const playersRouter = require('./routes/players');

// Create Express app
const app = express();

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*', // Configure allowed origins in production
  credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Trust proxy for accurate IP addresses
app.set('trust proxy', true);

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path} - IP: ${req.ip}`);
  next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const dbConnected = await db.testConnection();
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: dbConnected ? 'connected' : 'disconnected',
      version: '1.0.0'
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      database: 'error',
      error: error.message
    });
  }
});

// API routes
app.use('/api/codes', codesRouter);
app.use('/api/requests', requestsRouter);
app.use('/api/grants', grantsRouter);
app.use('/api/players', playersRouter);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Minecraft Church Verification System API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: '/health',
      codes: {
        generate: 'POST /api/codes/generate'
      },
      requests: {
        submit: 'POST /api/requests/submit',
        list: 'GET /api/requests',
        get: 'GET /api/requests/:id',
        approve: 'POST /api/requests/:id/approve',
        reject: 'POST /api/requests/:id/reject'
      },
      grants: {
        pending: 'GET /api/grants/pending',
        markApplied: 'POST /api/grants/:id/applied',
        markFailed: 'POST /api/grants/:id/failed'
      },
      players: {
        register: 'POST /api/players/register',
        get: 'GET /api/players/:player_name'
      }
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: `Endpoint ${req.method} ${req.path} not found`
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: 'Internal server error',
    message: config.environment === 'development' ? err.message : 'An error occurred'
  });
});

// Start server
const PORT = config.api.port;
const HOST = config.api.host;

async function startServer() {
  try {
    // Test database connection
    console.log('Testing database connection...');
    const dbConnected = await db.testConnection();
    
    if (!dbConnected) {
      console.error('❌ Database connection failed!');
      console.error('Please check your database configuration in .env or config.js');
      process.exit(1);
    }

    console.log('✅ Database connection successful!');

    // Start HTTP server
    app.listen(PORT, HOST, () => {
      console.log('');
      console.log('🚀 Minecraft Church Verification System API');
      console.log(`📡 Server running on http://${HOST}:${PORT}`);
      console.log(`🌍 Environment: ${config.environment}`);
      console.log(`📊 Health check: http://${HOST}:${PORT}/health`);
      console.log('');
    });

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  process.exit(0);
});

// Start the server
startServer();

module.exports = app;
