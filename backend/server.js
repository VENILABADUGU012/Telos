require('dotenv').config();
const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Server } = require('socket.io');

const { connectDB } = require('./src/config/db');
const setupSockets = require('./src/sockets/socketHandler');

// Route imports
const authRoutes = require('./src/routes/authRoutes');
const taskRoutes = require('./src/routes/taskRoutes');
const trackRoutes = require('./src/routes/trackRoutes');
const messageRoutes = require('./src/routes/messageRoutes');
const postRoutes = require('./src/routes/postRoutes');
const analyticsRoutes = require('./src/routes/analyticsRoutes');
const searchRoutes = require('./src/routes/searchRoutes');
const aiRoutes = require('./src/routes/aiRoutes');
const pointsRoutes = require('./src/routes/pointsRoutes');

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  },
});

setupSockets(io);

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));
app.use(morgan('dev'));

// Connect Database
connectDB();

// Health Check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'online',
    app: 'TELOS Mobile Backend API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/tracks', trackRoutes);
app.use('/api/v1/messages', messageRoutes);
app.use('/api/v1/posts', postRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/search', searchRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/points', pointsRoutes);

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error('[Server Error]', err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`===============================================`);
  console.log(`🚀 TELOS Backend Server running on port ${PORT}`);
  console.log(`📡 Local API:    http://localhost:${PORT}/api/health`);
  console.log(`🌐 Network API:  http://0.0.0.0:${PORT}/api/health`);
  console.log(`===============================================`);
});
