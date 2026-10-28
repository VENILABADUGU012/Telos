const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema(
  {
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, default: '' },
    mediaUrls: [{ type: String }],
    likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    comments: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
        text: { type: String, required: true },
        createdAt: { type: Date, default: Date.now },
      },
    ],
    sharesCount: { type: Number, default: 0 },
    visibility: {
      type: String,
      enum: ['public', 'private'],
      default: 'public',
    },
    isArchived: { type: Boolean, default: false },
  },
  { timestamps: true }
);

PostSchema.index({ author: 1, createdAt: -1 });

module.exports = mongoose.model('Post', PostSchema);
