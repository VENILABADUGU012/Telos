const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'urgent'],
      default: 'medium',
    },
    scheduledDate: { type: Date, required: true },
    scheduledTime: { type: String, default: null }, // e.g. "14:30"
    isAllDay: { type: Boolean, default: false },
    isAllDayUntilComplete: { type: Boolean, default: false },
    deadline: { type: Date, default: null },
    status: {
      type: String,
      enum: ['pending', 'in_progress', 'completed'],
      default: 'pending',
    },
    repeatConfig: {
      type: {
        type: String,
        enum: ['none', 'daily', 'weekdays', 'weekly', 'monthly', 'custom', 'repeat_until_completed'],
        default: 'none',
      },
      selectedDays: [{ type: Number }], // 1 = Mon, 7 = Sun
      startDate: { type: Date },
      endDate: { type: Date },
      customIntervalDays: { type: Number, default: 1 },
    },
    completedOccurrences: [
      {
        dateStr: { type: String, required: true }, // "YYYY-MM-DD"
        completedAt: { type: Date, default: Date.now },
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      },
    ],
    attachments: [
      {
        name: String,
        url: String,
        fileType: String,
        size: Number,
      },
    ],
    trackId: { type: mongoose.Schema.Types.ObjectId, ref: 'Track', default: null },
    groupConversationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', default: null },
    creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    assignedTo: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    collaborators: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        name: { type: String, default: '' },
        role: { type: String, enum: ['owner', 'admin', 'member'], default: 'member' },
        customRole: { type: String, default: '' },
        joined: { type: Boolean, default: false },
        completed: { type: Boolean, default: false },
      },
    ],
    visibility: {
      type: String,
      enum: ['private', 'public'],
      default: 'private',
    },
    inviteCode: { type: String, sparse: true },
    invitePasscode: { type: String, default: '' },
    shareUrl: { type: String, default: '' },
    completedAt: { type: Date, default: null },
    pointsEarned: { type: Number, default: 0 },
    aiGenerated: { type: Boolean, default: false },
    activityHistory: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        action: String,
        timestamp: { type: Date, default: Date.now },
        details: String,
      },
    ],
    comments: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        text: String,
        createdAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

TaskSchema.index({ creator: 1, scheduledDate: 1 });
TaskSchema.index({ assignedTo: 1, scheduledDate: 1 });
TaskSchema.index({ trackId: 1 });
TaskSchema.index({ 'completedOccurrences.dateStr': 1 });

module.exports = mongoose.model('Task', TaskSchema);
