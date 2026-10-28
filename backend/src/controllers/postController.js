const Post = require('../models/Post');
const User = require('../models/User');
const Track = require('../models/Track');

// 1. Get User Profile Data & Posts
exports.getUserProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const targetUserId = userId || req.user._id;

    const user = await User.findById(targetUserId).select('-googleId');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const isOwner = req.user._id.toString() === targetUserId.toString();

    // Fetch tracks: if owner, return public & private; if visitor, ONLY public
    const trackQuery = { creator: targetUserId };
    if (!isOwner) {
      trackQuery.visibility = 'public';
    }
    const tracks = await Track.find(trackQuery).sort({ createdAt: -1 });

    // Fetch user posts
    const postQuery = { author: targetUserId, isArchived: false };
    if (!isOwner && user.profileVisibility === 'private') {
      // Private profile visible only if authorized
      return res.status(200).json({
        success: true,
        user: {
          _id: user._id,
          displayName: user.displayName,
          username: user.username,
          avatarUrl: user.avatarUrl,
          bio: 'This account is private',
          profileVisibility: 'private',
        },
        tracks: [],
        posts: [],
      });
    }

    const posts = await Post.find(postQuery)
      .populate('author', 'displayName username avatarUrl')
      .populate('comments.user', 'displayName username avatarUrl')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      user,
      isOwner,
      tracks,
      posts,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Create Post
exports.createPost = async (req, res) => {
  try {
    const { text, mediaUrls, visibility } = req.body;
    if (!text && (!mediaUrls || mediaUrls.length === 0)) {
      return res.status(400).json({ success: false, message: 'Text or media is required' });
    }

    const post = await Post.create({
      author: req.user._id,
      text: text || '',
      mediaUrls: mediaUrls || [],
      visibility: visibility || 'public',
    });

    const populated = await Post.findById(post._id).populate('author', 'displayName username avatarUrl');
    return res.status(201).json({ success: true, post: populated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Like / Unlike Post
exports.toggleLike = async (req, res) => {
  try {
    const { postId } = req.params;
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    const likedIndex = post.likes.findIndex((id) => id.toString() === req.user._id.toString());
    if (likedIndex > -1) {
      post.likes.splice(likedIndex, 1);
    } else {
      post.likes.push(req.user._id);
    }

    await post.save();
    return res.status(200).json({ success: true, likesCount: post.likes.length, isLiked: likedIndex === -1 });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Add Comment
exports.addComment = async (req, res) => {
  try {
    const { postId } = req.params;
    const { text } = req.body;
    if (!text) return res.status(400).json({ success: false, message: 'Comment text is required' });

    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    post.comments.push({
      user: req.user._id,
      text,
      createdAt: new Date(),
    });

    await post.save();
    const updated = await Post.findById(postId).populate('comments.user', 'displayName username avatarUrl');
    return res.status(201).json({ success: true, comments: updated.comments });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. Delete or Archive Post
exports.deletePost = async (req, res) => {
  try {
    const { postId } = req.params;
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ success: false, message: 'Post not found' });

    if (post.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    await Post.findByIdAndDelete(postId);
    return res.status(200).json({ success: true, message: 'Post deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
