const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const generateSessionToken = (user) => {
  return jwt.sign(
    { userId: user._id, email: user.email, name: user.displayName },
    process.env.JWT_SECRET || 'telos_jwt_secure_key_prod_development_9982348',
    { expiresIn: '30d' }
  );
};

// 1. Google Sign-In / Sign-Up
exports.googleAuth = async (req, res) => {
  try {
    const { idToken, demoMode, email: demoEmail, displayName: demoName } = req.body;

    let email, name, picture, googleId;

    if (demoMode || process.env.NODE_ENV === 'development' && !idToken) {
      // Resilient fallback for testing before user configures Google Cloud OAuth Client ID
      email = demoEmail || 'demo.user@telos.app';
      name = demoName || 'Telos Explorer';
      picture = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
      googleId = 'demo-google-id-' + Buffer.from(email).toString('hex').slice(0, 10);
    } else {
      if (!idToken) {
        return res.status(400).json({ success: false, message: 'Google idToken is required' });
      }

      // Server-side verification of Google ID Token
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      email = payload.email;
      name = payload.name;
      picture = payload.picture;
      googleId = payload.sub;
    }

    let user = await User.findOne({ email });

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      user = await User.create({
        googleId,
        email,
        displayName: name,
        avatarUrl: picture || '',
        isOnboarded: false,
        points: 50, // Initial welcome points
      });
    } else if (!user.googleId) {
      user.googleId = googleId;
      if (picture && !user.avatarUrl) user.avatarUrl = picture;
      await user.save();
    }

    const token = generateSessionToken(user);

    return res.status(200).json({
      success: true,
      message: isNewUser ? 'Account created successfully' : 'Signed in successfully',
      isNewUser,
      requiresOnboarding: !user.isOnboarded,
      token,
      user,
    });
  } catch (error) {
    console.error('[Auth Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication failed: ' + error.message,
    });
  }
};

// 2. Onboarding complete
exports.completeOnboarding = async (req, res) => {
  try {
    const { username, displayName, avatarUrl, profileVisibility, notificationPreferences } = req.body;

    if (username) {
      const existing = await User.findOne({ username: username.toLowerCase(), _id: { $ne: req.user._id } });
      if (existing) {
        return res.status(400).json({ success: false, message: 'Username is already taken' });
      }
    }

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (username) user.username = username.toLowerCase().trim();
    if (displayName) user.displayName = displayName.trim();
    if (avatarUrl) user.avatarUrl = avatarUrl;
    if (profileVisibility) user.profileVisibility = profileVisibility;
    if (notificationPreferences) {
      user.notificationPreferences = { ...user.notificationPreferences, ...notificationPreferences };
    }

    user.isOnboarded = true;
    await user.save();

    return res.status(200).json({
      success: true,
      message: 'Onboarding completed successfully',
      user,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Get Current User / Restore Session
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(200).json({ success: true, user: req.user });
    }
    return res.status(200).json({ success: true, user });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Update Profile
exports.updateProfile = async (req, res) => {
  try {
    const { displayName, bio, avatarUrl, profileVisibility, themePreference, languagePreference } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (displayName) user.displayName = displayName;
    if (bio !== undefined) user.bio = bio;
    if (avatarUrl) user.avatarUrl = avatarUrl;
    if (profileVisibility) user.profileVisibility = profileVisibility;
    if (themePreference) user.themePreference = themePreference;
    if (languagePreference) user.languagePreference = languagePreference;

    await user.save();
    return res.status(200).json({ success: true, user });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
