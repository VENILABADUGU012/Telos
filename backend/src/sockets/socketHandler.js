const jwt = require('jsonwebtoken');

const setupSockets = (io) => {
  // Authentication middleware for socket connections
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) {
      return next(); // allow guest/dev or reject in strict mode
    }
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'telos_jwt_secure_key_prod_development_9982348');
      socket.user = decoded;
      next();
    } catch {
      next();
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user?.userId || socket.id;
    socket.join(`user_${userId}`);
    console.log(`[Socket] Client connected: ${socket.id} (User: ${userId})`);

    // Join conversation or track room
    socket.on('join_room', (roomId) => {
      socket.join(roomId);
      console.log(`[Socket] User joined room: ${roomId}`);
    });

    // Leave room
    socket.on('leave_room', (roomId) => {
      socket.leave(roomId);
      console.log(`[Socket] User left room: ${roomId}`);
    });

    // Real-time Chat message
    socket.on('send_message', (data) => {
      // Broadcast to room
      if (data.roomId) {
        socket.to(data.roomId).emit('receive_message', data);
      }
    });

    // Real-time Task status toggle sync
    socket.on('task_updated', (data) => {
      if (data.trackId) {
        socket.to(`track_${data.trackId}`).emit('task_status_changed', data);
      }
      io.emit('task_sync', data);
    });

    // WebRTC Calling Signaling
    socket.on('call_user', ({ userToCall, signalData, from, fromName, callType }) => {
      io.to(`user_${userToCall}`).emit('incoming_call', {
        signal: signalData,
        from,
        fromName,
        callType, // 'audio' or 'video'
      });
    });

    socket.on('answer_call', ({ to, signal }) => {
      io.to(`user_${to}`).emit('call_accepted', signal);
    });

    socket.on('ice_candidate', ({ to, candidate }) => {
      io.to(`user_${to}`).emit('ice_candidate', candidate);
    });

    socket.on('end_call', ({ to }) => {
      io.to(`user_${to}`).emit('call_ended');
    });

    socket.on('disconnect', () => {
      console.log(`[Socket] Client disconnected: ${socket.id}`);
    });
  });
};

module.exports = setupSockets;
