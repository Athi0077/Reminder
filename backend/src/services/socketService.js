const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const initSocket = (server) => {
  const io = socketIo(server, {
    cors: {
      origin: '*', // Adjust to specific frontend URL in production
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    }
  });

  // Socket.IO authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('-password');
      
      if (!user) {
        return next(new Error('Authentication error: User not found'));
      }

      socket.user = user;
      next();
    } catch (error) {
      console.error('Socket authentication error:', error);
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}, User ID: ${socket.user._id}`);
    
    // Join personal user room
    const userId = socket.user._id.toString();
    socket.join(`user:${userId}`);

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}, User ID: ${socket.user._id}`);
    });
  });

  return io;
};

module.exports = { initSocket };
