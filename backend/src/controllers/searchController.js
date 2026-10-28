const Task = require('../models/Task');
const Track = require('../models/Track');
const User = require('../models/User');
const Post = require('../models/Post');
const Template = require('../models/Template');
const Conversation = require('../models/Conversation');

exports.globalSearch = async (req, res) => {
  try {
    const { q, type } = req.query;
    if (!q || q.trim() === '') {
      return res.status(200).json({ success: true, results: { tasks: [], tracks: [], users: [], posts: [], navigation: [] } });
    }

    const regex = new RegExp(q.trim(), 'i');
    const results = {};

    // 1. Navigation / UI commands recognition
    const queryLower = q.toLowerCase();
    const navigationActions = [];

    if (queryLower.includes('track') && (queryLower.includes('create') || queryLower.includes('new'))) {
      navigationActions.push({ title: 'Create a Track', route: '/add?type=track', icon: 'route' });
    }
    if (queryLower.includes('task') && (queryLower.includes('create') || queryLower.includes('new') || queryLower.includes('add'))) {
      navigationActions.push({ title: 'Create a Task', route: '/add?type=task', icon: 'add_task' });
    }
    if (queryLower.includes('setting') || queryLower.includes('notification') || queryLower.includes('theme')) {
      navigationActions.push({ title: 'Open Settings', route: '/settings', icon: 'settings' });
    }
    if (queryLower.includes('reward') || queryLower.includes('point') || queryLower.includes('chest')) {
      navigationActions.push({ title: 'Open Points Chest', route: '/rewards', icon: 'military_tech' });
    }
    if (queryLower.includes('chat') || queryLower.includes('message')) {
      navigationActions.push({ title: 'Open Messages', route: '/messages', icon: 'chat' });
    }
    if (queryLower.includes('ai') || queryLower.includes('assistant') || queryLower.includes('plan')) {
      navigationActions.push({ title: 'Ask AI Chatbot', route: `/ai-chatbot?prompt=${encodeURIComponent(q)}`, icon: 'smart_toy' });
    }

    results.navigation = navigationActions;

    // 2. Tasks Search (Authorized: user's tasks or public)
    if (!type || type === 'tasks') {
      results.tasks = await Task.find({
        $and: [
          { $or: [{ title: regex }, { description: regex }] },
          { $or: [{ creator: req.user._id }, { assignedTo: req.user._id }, { visibility: 'public' }] },
        ],
      })
        .select('title scheduledDate status visibility trackId')
        .limit(10);
    }

    // 3. Tracks Search (Authorized: user's tracks or public)
    if (!type || type === 'tracks') {
      results.tracks = await Track.find({
        $and: [
          { $or: [{ title: regex }, { description: regex }] },
          { $or: [{ creator: req.user._id }, { 'collaborators.user': req.user._id }, { visibility: 'public' }] },
        ],
      })
        .select('title description progress visibility category')
        .limit(10);
    }

    // 4. Users Search
    if (!type || type === 'users') {
      results.users = await User.find({
        $or: [{ displayName: regex }, { username: regex }],
        profileVisibility: 'public',
      })
        .select('displayName username avatarUrl bio')
        .limit(10);
    }

    // 5. Posts Search (public posts only)
    if (!type || type === 'posts') {
      results.posts = await Post.find({
        text: regex,
        visibility: 'public',
        isArchived: false,
      })
        .populate('author', 'displayName username avatarUrl')
        .limit(10);
    }

    // 6. Templates Search
    if (!type || type === 'templates') {
      results.templates = await Template.find({
        $or: [{ title: regex }, { description: regex }],
      }).limit(5);
    }

    return res.status(200).json({
      success: true,
      query: q,
      results,
      aiHandoff: {
        suggested: results.navigation.length === 0 && (results.tasks?.length || 0) + (results.tracks?.length || 0) === 0,
        prompt: q,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
