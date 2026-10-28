const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    googleId: { type: String, unique: true, sparse: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    displayName: { type: String, required: true, trim: true },
    username: { type: String, unique: true, sparse: true, trim: true, lowercase: true },
    avatarUrl: { type: String, default: '' },
    bio: { type: String, default: '', maxLength: 300 },
    profileVisibility: {
      type: String,
      enum: ['public', 'private'],
      default: 'public',
    },
    isOnboarded: { type: Boolean, default: false },
    notificationPreferences: {
      taskReminders: { type: Boolean, default: true },
      deadlineReminders: { type: Boolean, default: true },
      recurringTaskReminders: { type: Boolean, default: true },
      trackActivity: { type: Boolean, default: true },
      collaboratorInvitations: { type: Boolean, default: true },
      taskAssignment: { type: Boolean, default: true },
      groupMessages: { type: Boolean, default: true },
      individualMessages: { type: Boolean, default: true },
      likesAndComments: { type: Boolean, default: true },
      aiPlanningUpdates: { type: Boolean, default: true },
    },
    themePreference: {
      type: String,
      enum: ['system', 'light', 'dark'],
      default: 'dark',
    },
    languagePreference: {
      type: String,
      default: 'en',
    },
    points: { type: Number, default: 0 },
    streakDays: { type: Number, default: 0 },
    lastActiveDate: { type: Date, default: Date.now },
    achievements: [
      {
        id: String,
        title: String,
        description: String,
        unlockedAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', UserSchema);
