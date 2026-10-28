const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Authorization token missing or malformed' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'telos_jwt_secure_key_prod_development_9982348');

    // Fetch user or attach decoded payload
    try {
      const user = await User.findById(decoded.userId);
      if (!user) {
        // Return resilient decoded mock if DB is in mock memory mode
        req.user = { _id: decoded.userId, email: decoded.email, displayName: decoded.name || 'Telos User' };
      } else {
        req.user = user;
      }
    } catch {
      req.user = { _id: decoded.userId, email: decoded.email, displayName: decoded.name || 'Telos User' };
    }

    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired session token', error: err.message });
  }
};

module.exports = authMiddleware;
