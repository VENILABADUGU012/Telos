const mongoose = require('mongoose');

const TrackSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    visibility: {
      type: String,
      enum: ['private', 'public'],
      default: 'private',
    },
    category: {
      type: String,
      enum: ['productivity', 'academic', 'project', 'fitness', 'career', 'personal', 'other'],
      default: 'productivity',
    },
    creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    collaborators: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        role: { type: String, enum: ['owner', 'admin', 'member'], default: 'member' },
        customRole: { type: String, default: '' },
        joinedAt: { type: Date, default: Date.now },
      },
    ],
    milestones: [
      {
        title: { type: String, required: true },
        targetDate: { type: Date, required: true },
        completed: { type: Boolean, default: false },
        completedAt: { type: Date, default: null },
      },
    ],
    weeklyPlans: [
      {
        weekNumber: { type: Number, required: true },
        startDate: { type: Date, required: true },
        endDate: { type: Date, required: true },
        goals: [{ type: String }],
        taskIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
      },
    ],
    monthlyPlans: [
      {
        monthIndex: { type: Number, required: true },
        name: { type: String },
        goals: [{ type: String }],
        taskIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
      },
    ],
    progress: {
      percentage: { type: Number, default: 0 },
      totalTasks: { type: Number, default: 0 },
      completedTasks: { type: Number, default: 0 },
      pendingTasks: { type: Number, default: 0 },
      inProgressTasks: { type: Number, default: 0 },
    },
    isTemplate: { type: Boolean, default: false },
    sourceTemplateId: { type: mongoose.Schema.Types.ObjectId, ref: 'Template', default: null },
    activityHistory: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        action: String,
        details: String,
        timestamp: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

TrackSchema.index({ creator: 1 });
TrackSchema.index({ visibility: 1 });

module.exports = mongoose.model('Track', TrackSchema);
