require('dotenv').config();
const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);
dns.setDefaultResultOrder('ipv4first');
const app = require('./app');
const http = require('http');
const { initSocket } = require('./services/socketService');
const connectDB = require('./config/database');

const PORT = process.env.PORT || 5000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = initSocket(server);

// Attach io to app so it can be used in controllers
app.set('io', io);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Connect to MongoDB
connectDB().catch(err => {
  console.error('Failed to connect to MongoDB', err);
});
