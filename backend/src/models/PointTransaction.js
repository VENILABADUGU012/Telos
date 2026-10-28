const mongoose = require('mongoose');

const PointTransactionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    points: { type: Number, required: true },
    reason: {
      type: String,
      enum: ['task_completed', 'milestone_reached', 'streak_bonus', 'track_completed', 'daily_goal_met'],
      required: true,
    },
    referenceId: { type: mongoose.Schema.Types.ObjectId, default: null },
    referenceModel: { type: String, default: null },
    description: { type: String, default: '' },
  },
  { timestamps: true }
);

PointTransactionSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('PointTransaction', PointTransactionSchema);
