const mongoose = require('mongoose');

const ActivityLogSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    action: { type: String, required: true }, // e.g., 'created_task', 'completed_task', 'joined_track'
    entityType: {
      type: String,
      enum: ['task', 'track', 'conversation', 'post', 'milestone', 'template'],
      required: true,
    },
    entityId: { type: mongoose.Schema.Types.ObjectId, required: true },
    trackId: { type: mongoose.Schema.Types.ObjectId, ref: 'Track', default: null },
    details: { type: String, default: '' },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

ActivityLogSchema.index({ entityId: 1, createdAt: -1 });
ActivityLogSchema.index({ trackId: 1, createdAt: -1 });

module.exports = mongoose.model('ActivityLog', ActivityLogSchema);
