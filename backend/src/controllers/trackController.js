const Track = require('../models/Track');
const Task = require('../models/Task');
const Template = require('../models/Template');
const Conversation = require('../models/Conversation');
const ActivityLog = require('../models/ActivityLog');

// 1. Get User's Tracks ("YOUR TRACKS")
exports.getUserTracks = async (req, res) => {
  try {
    const { filter, sort } = req.query;
    let query = {
      $or: [{ creator: req.user._id }, { 'collaborators.user': req.user._id }],
    };

    const now = new Date();
    if (filter === 'active') {
      query.endDate = { $gte: now };
      query['progress.percentage'] = { $lt: 100 };
    } else if (filter === 'completed') {
      query['progress.percentage'] = 100;
    } else if (filter === 'upcoming') {
      query.startDate = { $gt: now };
    } else if (filter === 'public') {
      query.visibility = 'public';
    } else if (filter === 'private') {
      query.visibility = 'private';
    } else if (filter === 'collaborative') {
      query['collaborators.1'] = { $exists: true };
    }

    let sortOption = { updatedAt: -1 };
    if (sort === 'startDate') sortOption = { startDate: 1 };
    else if (sort === 'deadline') sortOption = { endDate: 1 };
    else if (sort === 'progress') sortOption = { 'progress.percentage': -1 };

    const tracks = await Track.find(query)
      .populate('creator', 'displayName username avatarUrl')
      .populate('collaborators.user', 'displayName username avatarUrl')
      .sort(sortOption);

    return res.status(200).json({ success: true, count: tracks.length, tracks });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Create Track (Manual, AI, or Template)
exports.createTrack = async (req, res) => {
  try {
    const {
      title,
      description,
      startDate,
      endDate,
      visibility,
      category,
      milestones,
      weeklyPlans,
      monthlyPlans,
      tasks, // optional initial tasks array
      collaborators,
    } = req.body;

    if (!title || !startDate || !endDate) {
      return res.status(400).json({ success: false, message: 'Title, startDate, and endDate are required' });
    }

    const track = new Track({
      title,
      description: description || '',
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      visibility: visibility || 'private',
      category: category || 'productivity',
      creator: req.user._id,
      collaborators: collaborators || [{ user: req.user._id, role: 'owner' }],
      milestones: milestones || [],
      weeklyPlans: weeklyPlans || [],
      monthlyPlans: monthlyPlans || [],
    });

    await track.save();

    // Create isolated Track Chat room automatically
    await Conversation.create({
      type: 'track',
      trackId: track._id,
      name: `${title} Discussion`,
      members: [{ user: req.user._id, role: 'admin' }],
    });

    // If initial tasks provided, insert them linked to track
    if (tasks && Array.isArray(tasks) && tasks.length > 0) {
      const createdTasks = [];
      for (const t of tasks) {
        const newTask = await Task.create({
          title: t.title,
          description: t.description || '',
          scheduledDate: t.scheduledDate ? new Date(t.scheduledDate) : new Date(startDate),
          scheduledTime: t.scheduledTime || null,
          deadline: t.deadline ? new Date(t.deadline) : new Date(endDate),
          trackId: track._id,
          creator: req.user._id,
          assignedTo: [req.user._id],
          visibility: visibility || 'private',
        });
        createdTasks.push(newTask._id);
      }
      track.progress.totalTasks = createdTasks.length;
      track.progress.pendingTasks = createdTasks.length;
      await track.save();
    }

    await ActivityLog.create({
      user: req.user._id,
      action: 'created_track',
      entityType: 'track',
      entityId: track._id,
      trackId: track._id,
      details: `Created track "${title}"`,
    });

    return res.status(201).json({ success: true, track });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Track Details & Options (A through H)
exports.getTrackDetails = async (req, res) => {
  try {
    const { trackId } = req.params;
    const track = await Track.findById(trackId)
      .populate('creator', 'displayName username avatarUrl')
      .populate('collaborators.user', 'displayName username avatarUrl');

    if (!track) return res.status(404).json({ success: false, message: 'Track not found' });

    // Fetch tasks belonging to this track
    const tasks = await Task.find({ trackId }).sort({ scheduledDate: 1 });

    // Fetch activity history
    const activityTimeline = await ActivityLog.find({ trackId })
      .populate('user', 'displayName username avatarUrl')
      .sort({ createdAt: -1 })
      .limit(50);

    // Fetch track conversation
    const conversation = await Conversation.findOne({ trackId, type: 'track' });

    return res.status(200).json({
      success: true,
      track,
      tasks,
      activityTimeline,
      chatRoomId: conversation ? conversation._id : null,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Update Track
exports.updateTrack = async (req, res) => {
  try {
    const { trackId } = req.params;
    const track = await Track.findById(trackId);
    if (!track) return res.status(404).json({ success: false, message: 'Track not found' });

    Object.assign(track, req.body);
    await track.save();

    await ActivityLog.create({
      user: req.user._id,
      action: 'updated_track',
      entityType: 'track',
      entityId: track._id,
      trackId: track._id,
      details: `Track "${track.title}" details updated`,
    });

    return res.status(200).json({ success: true, track });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. Collaborate With Others (Explore Public Tracks)
exports.getPublicTracks = async (req, res) => {
  try {
    const { search, category } = req.query;
    let query = { visibility: 'public' };

    if (category && category !== 'all') {
      query.category = category;
    }
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    const tracks = await Track.find(query)
      .populate('creator', 'displayName username avatarUrl')
      .populate('collaborators.user', 'displayName username avatarUrl')
      .sort({ createdAt: -1 })
      .limit(30);

    return res.status(200).json({ success: true, tracks });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 6. Join a Public Track
exports.joinTrack = async (req, res) => {
  try {
    const { trackId } = req.params;
    const track = await Track.findById(trackId);
    if (!track) return res.status(404).json({ success: false, message: 'Track not found' });

    const alreadyJoined = track.collaborators.some(
      (c) => c.user.toString() === req.user._id.toString()
    );

    if (alreadyJoined) {
      return res.status(400).json({ success: false, message: 'Already a member of this track' });
    }

    track.collaborators.push({
      user: req.user._id,
      role: 'member',
      joinedAt: new Date(),
    });
    await track.save();

    // Also add to track conversation
    await Conversation.findOneAndUpdate(
      { trackId, type: 'track' },
      { $addToSet: { members: { user: req.user._id, role: 'member' } } }
    );

    await ActivityLog.create({
      user: req.user._id,
      action: 'joined_track',
      entityType: 'track',
      entityId: track._id,
      trackId: track._id,
      details: `${req.user.displayName || 'User'} joined the track`,
    });

    return res.status(200).json({ success: true, message: 'Joined track successfully', track });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 7. Explore & Apply Templates
exports.getTemplates = async (req, res) => {
  try {
    let templates = await Template.find().sort({ usageCount: -1 });

    // Seed standard templates if none exist
    if (templates.length === 0) {
      const seedTemplates = [
        {
          title: 'Exam Mastery & Academic Sprint',
          description: 'A 4-week structured sprint with weekly milestones, revision cycles, and mock exams.',
          category: 'academic',
          durationWeeks: 4,
          durationMonths: 1,
          tasksTemplate: [
            { title: 'Syllabus breakdown & resource mapping', dayOffset: 1 },
            { title: 'Deep study: High-yield Module 1', dayOffset: 3 },
            { title: 'Solve 50 past paper problems', dayOffset: 7 },
            { title: 'Mid-sprint comprehensive review', dayOffset: 14 },
            { title: 'Timed full-length mock exam 1', dayOffset: 21 },
            { title: 'Final formula drill and weak areas sprint', dayOffset: 27 },
          ],
          milestonesTemplate: [
            { title: 'Week 1 Foundation Complete', dayOffset: 7 },
            { title: 'Mid-Sprint 50% Mastery', dayOffset: 14 },
            { title: 'All Mock Tests Completed', dayOffset: 24 },
          ],
        },
        {
          title: 'Full-Stack Software Launch Roadmap',
          description: 'Complete 30-day product launch track from architecture to MVP, testing, and production deployment.',
          category: 'project',
          durationWeeks: 4,
          durationMonths: 1,
          tasksTemplate: [
            { title: 'System architecture & data schema design', dayOffset: 1 },
            { title: 'Core API endpoints & database connection', dayOffset: 5 },
            { title: 'Mobile UI screens & state management setup', dayOffset: 10 },
            { title: 'Real-time WebSocket & push notification integration', dayOffset: 18 },
            { title: 'End-to-end integration tests & bug fixes', dayOffset: 25 },
            { title: 'App store release build & production deploy', dayOffset: 30 },
          ],
          milestonesTemplate: [
            { title: 'Backend & Data Schema Approved', dayOffset: 6 },
            { title: 'Feature Complete MVP', dayOffset: 20 },
            { title: 'Production Go-Live', dayOffset: 30 },
          ],
        },
        {
          title: '30-Day Peak Fitness & Habit Transformation',
          description: 'Progressive strength, endurance, and mindfulness daily discipline system.',
          category: 'fitness',
          durationWeeks: 4,
          durationMonths: 1,
          tasksTemplate: [
            { title: 'Baseline fitness assessment & biometric check', dayOffset: 1 },
            { title: 'Morning hydration & 30-min brisk outdoor run', dayOffset: 2, repeatType: 'daily' },
            { title: 'Strength training: Upper body focus', dayOffset: 4 },
            { title: 'Strength training: Lower body & core', dayOffset: 6 },
            { title: 'Active recovery walk & mobility stretch', dayOffset: 7 },
          ],
          milestonesTemplate: [
            { title: 'Week 1 Habit Consistency', dayOffset: 7 },
            { title: 'Halfway Benchmark Reached', dayOffset: 15 },
            { title: '30-Day Milestone Completed', dayOffset: 30 },
          ],
        },
      ];

      templates = await Template.insertMany(seedTemplates);
    }

    return res.status(200).json({ success: true, templates });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 8. Add Template to User's Tracks
exports.applyTemplate = async (req, res) => {
  try {
    const { templateId } = req.params;
    const { startDate, titleOverride } = req.body;

    const template = await Template.findById(templateId);
    if (!template) return res.status(404).json({ success: false, message: 'Template not found' });

    const start = startDate ? new Date(startDate) : new Date();
    const end = new Date(start);
    end.setDate(end.getDate() + template.durationWeeks * 7);

    // Calculate milestone dates
    const milestones = (template.milestonesTemplate || []).map((m) => {
      const targetDate = new Date(start);
      targetDate.setDate(targetDate.getDate() + (m.dayOffset || 0));
      return { title: m.title, targetDate, completed: false };
    });

    const newTrack = await Track.create({
      title: titleOverride || template.title,
      description: template.description,
      startDate: start,
      endDate: end,
      category: template.category,
      creator: req.user._id,
      collaborators: [{ user: req.user._id, role: 'owner' }],
      milestones,
      sourceTemplateId: template._id,
      progress: {
        totalTasks: template.tasksTemplate.length,
        completedTasks: 0,
        pendingTasks: template.tasksTemplate.length,
        inProgressTasks: 0,
        percentage: 0,
      },
    });

    // Create tasks for track
    for (const item of template.tasksTemplate) {
      const taskDate = new Date(start);
      taskDate.setDate(taskDate.getDate() + (item.dayOffset || 0));

      await Task.create({
        title: item.title,
        description: item.description || '',
        scheduledDate: taskDate,
        trackId: newTrack._id,
        creator: req.user._id,
        assignedTo: [req.user._id],
        repeatConfig: { type: item.repeatType || 'none' },
      });
    }

    await Template.findByIdAndUpdate(templateId, { $inc: { usageCount: 1 } });

    // Track chat
    await Conversation.create({
      type: 'track',
      trackId: newTrack._id,
      name: `${newTrack.title} Chat`,
      members: [{ user: req.user._id, role: 'admin' }],
    });

    return res.status(201).json({ success: true, track: newTrack });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
