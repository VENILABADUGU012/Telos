const mongoose = require('mongoose');

let isConnected = false;

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/telos_db', {
      serverSelectionTimeoutMS: 5000,
    });
    isConnected = true;
    console.log(`[Database] MongoDB connected successfully: ${conn.connection.host}`);
  } catch (error) {
    isConnected = false;
    console.warn(`[Database] MongoDB connection warning: ${error.message}`);
    console.warn(`[Database] Operating in resilient memory mode until MongoDB service starts.`);
  }
};

const getStatus = () => isConnected;

module.exports = { connectDB, getStatus };
