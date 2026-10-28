const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema(
  {
    conversationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', required: true },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, default: '' },
    attachments: [
      {
        name: String,
        url: String,
        fileType: String,
        size: Number,
      },
    ],
    voiceUrl: { type: String, default: null },
    voiceDurationSeconds: { type: Number, default: 0 },
    poll: {
      question: String,
      options: [
        {
          text: String,
          votes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
        },
      ],
    },
    callMeta: {
      callType: { type: String, enum: ['audio', 'video'], default: null },
      status: { type: String, enum: ['initiated', 'missed', 'completed', 'declined'], default: null },
      durationSeconds: { type: Number, default: 0 },
    },
    reactions: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        emoji: String,
      },
    ],
    replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

MessageSchema.index({ conversationId: 1, createdAt: -1 });

module.exports = mongoose.model('Message', MessageSchema);
