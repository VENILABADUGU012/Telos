const mongoose = require('mongoose');

const ConversationSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['individual', 'group', 'track'],
      required: true,
    },
    trackId: { type: mongoose.Schema.Types.ObjectId, ref: 'Track', default: null },
    name: { type: String, default: '' },
    avatarUrl: { type: String, default: '' },
    members: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
        role: { type: String, enum: ['admin', 'member'], default: 'member' },
        joinedAt: { type: Date, default: Date.now },
      },
    ],
    lastMessage: {
      text: String,
      senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      createdAt: Date,
    },
    groupTasks: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Conversation', ConversationSchema);
