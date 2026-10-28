const crypto = require('crypto');
const Task = require('../models/Task');
const Track = require('../models/Track');
const User = require('../models/User');
const PointTransaction = require('../models/PointTransaction');
const ActivityLog = require('../models/ActivityLog');

// Helper to recalculate track progress accurately
const recalculateTrackProgress = async (trackId) => {
  if (!trackId) return;
  try {
    const tasks = await Task.find({ trackId });
    const total = tasks.length;
    let completed = 0;
    let inProgress = 0;

    tasks.forEach((t) => {
      if (t.status === 'completed') {
        completed++;
      } else if (t.completedOccurrences && t.completedOccurrences.length > 0) {
        // If recurring and has completed occurrences
        completed++;
      } else if (t.status === 'in_progress') {
        inProgress++;
      }
    });

    const pending = Math.max(0, total - completed - inProgress);
    const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

    await Track.findByIdAndUpdate(trackId, {
      'progress.totalTasks': total,
      'progress.completedTasks': completed,
      'progress.inProgressTasks': inProgress,
      'progress.pendingTasks': pending,
      'progress.percentage': percentage,
    });
  } catch (err) {
    console.error('Error recalculating track progress:', err.message);
  }
};

// 1. Get tasks for a given date with full recurring & timezone support
exports.getTasksByDate = async (req, res) => {
  try {
    const { date } = req.query; // YYYY-MM-DD
    let startOfDay, endOfDay, dateStr;

    if (date && date.includes('-')) {
      const [y, m, d] = date.split('-').map(Number);
      startOfDay = new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
      endOfDay = new Date(Date.UTC(y, m - 1, d, 23, 59, 59, 999));
      dateStr = date;
    } else {
      const now = new Date();
      startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
      endOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 23, 59, 59, 999));
      dateStr = now.toISOString().split('T')[0];
    }

    const queryDate = new Date(startOfDay);
    const dayOfWeek = queryDate.getUTCDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat
    const dayOfMonth = queryDate.getUTCDate();

    // Fetch candidate tasks
    const allCandidateTasks = await Task.find({
      $or: [
        { creator: req.user._id },
        { assignedTo: req.user._id },
        { 'collaborators.user': req.user._id },
        { visibility: 'public' },
      ],
    })
      .populate('creator', 'displayName username avatarUrl')
      .populate('assignedTo', 'displayName username avatarUrl')
      .populate('collaborators.user', 'displayName username avatarUrl')
      .populate('trackId', 'title progress')
      .sort({ scheduledDate: 1, scheduledTime: 1 });

    const matchingTasks = [];

    for (const t of allCandidateTasks) {
      const taskDate = new Date(t.scheduledDate);
      const taskStartUTC = new Date(Date.UTC(taskDate.getUTCFullYear(), taskDate.getUTCMonth(), taskDate.getUTCDate(), 0, 0, 0, 0));

      const repeatType = t.repeatConfig?.type || 'none';
      const repeatEnd = t.repeatConfig?.endDate ? new Date(t.repeatConfig.endDate) : null;

      // Check if after repeat end date
      if (repeatEnd && startOfDay > repeatEnd) {
        continue;
      }

      let isMatch = false;

      if (repeatType === 'none') {
        // One-time task matching day
        if (taskStartUTC.getTime() === startOfDay.getTime() || (taskDate >= startOfDay && taskDate <= endOfDay)) {
          isMatch = true;
        } else if (t.isAllDayUntilComplete && t.status !== 'completed' && taskStartUTC <= startOfDay) {
          // All Day Until Complete carries over until completed
          isMatch = true;
        }
      } else if (taskStartUTC <= endOfDay) {
        // Recurring task that started on or before query date
        if (repeatType === 'daily') {
          isMatch = true;
        } else if (repeatType === 'weekdays') {
          // Mon-Fri
          if (dayOfWeek >= 1 && dayOfWeek <= 5) isMatch = true;
        } else if (repeatType === 'weekly') {
          if (taskStartUTC.getUTCDay() === dayOfWeek) isMatch = true;
        } else if (repeatType === 'monthly') {
          if (taskStartUTC.getUTCDate() === dayOfMonth) isMatch = true;
        } else if (repeatType === 'repeat_until_completed') {
          if (t.status !== 'completed') isMatch = true;
        } else if (repeatType === 'custom') {
          const intervalDays = t.repeatConfig?.customIntervalDays || 1;
          const diffDays = Math.floor((startOfDay.getTime() - taskStartUTC.getTime()) / 86400000);
          if (diffDays >= 0 && diffDays % intervalDays === 0) isMatch = true;
        }
      }

      if (isMatch) {
        const taskObj = t.toObject();
        // Check if this specific occurrence date was completed
        const isOccurrenceCompleted = t.completedOccurrences?.some((o) => o.dateStr === dateStr);
        if (repeatType !== 'none') {
          taskObj.status = isOccurrenceCompleted ? 'completed' : t.status === 'completed' ? 'pending' : t.status;
        }
        taskObj.currentOccurrenceDate = dateStr;
        matchingTasks.push(taskObj);
      }
    }

    return res.status(200).json({ success: true, count: matchingTasks.length, tasks: matchingTasks });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Complete Task Creation Workflow with Full Validation
exports.createTask = async (req, res) => {
  try {
    const {
      title,
      description,
      priority,
      scheduledDate,
      scheduledTime,
      isAllDay,
      isAllDayUntilComplete,
      deadline,
      repeatConfig,
      attachments,
      trackId,
      groupConversationId,
      assignedTo,
      collaborators,
      visibility,
      invitePasscode,
      aiGenerated,
    } = req.body;

    // A. Validation
    if (!title || title.trim() === '') {
      return res.status(400).json({ success: false, message: 'Task title is required' });
    }
    if (!scheduledDate) {
      return res.status(400).json({ success: false, message: 'Scheduled date is required' });
    }

    const scheduledDateObj = new Date(scheduledDate);
    if (isNaN(scheduledDateObj.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid scheduled date format' });
    }

    let deadlineObj = null;
    if (deadline) {
      deadlineObj = new Date(deadline);
      if (isNaN(deadlineObj.getTime())) {
        return res.status(400).json({ success: false, message: 'Invalid deadline date format' });
      }
      if (deadlineObj < scheduledDateObj) {
        return res.status(400).json({ success: false, message: 'Deadline cannot be earlier than scheduled date' });
      }
    }

    // B. Prevent Duplicate Creation (Debounce within 3 seconds)
    const threeSecondsAgo = new Date(Date.now() - 3000);
    const duplicateCheck = await Task.findOne({
      creator: req.user._id,
      title: title.trim(),
      scheduledDate: scheduledDateObj,
      createdAt: { $gte: threeSecondsAgo },
    });
    if (duplicateCheck) {
      return res.status(200).json({ success: true, task: duplicateCheck, duplicatePrevented: true });
    }

    // C. Generate Passcode / Secure Invite Link
    const generatedPasscode = invitePasscode || crypto.randomBytes(3).toString('hex').toUpperCase();
    const generatedCode = crypto.randomBytes(4).toString('hex');
    const shareUrl = `https://telos.app/join/task/${generatedCode}`;

    // Format collaborators
    const formattedCollaborators = Array.isArray(collaborators) && collaborators.length > 0
      ? collaborators.map((c) => ({
          user: c.user || c.userId || req.user._id,
          name: c.name || '',
          role: c.role || 'member',
          customRole: c.customRole || '',
          joined: true,
          completed: false,
        }))
      : [{ user: req.user._id, role: 'owner', joined: true, completed: false }];

    // D. Build Task
    const task = new Task({
      title: title.trim(),
      description: description ? description.trim() : '',
      priority: ['low', 'medium', 'high', 'urgent'].includes(priority) ? priority : 'medium',
      scheduledDate: scheduledDateObj,
      scheduledTime: scheduledTime || null,
      isAllDay: Boolean(isAllDay),
      isAllDayUntilComplete: Boolean(isAllDayUntilComplete),
      deadline: deadlineObj,
      repeatConfig: repeatConfig || { type: 'none' },
      attachments: attachments || [],
      trackId: trackId || null,
      groupConversationId: groupConversationId || null,
      creator: req.user._id,
      assignedTo: assignedTo && assignedTo.length > 0 ? assignedTo : [req.user._id],
      collaborators: formattedCollaborators,
      visibility: visibility || 'private',
      inviteCode: generatedCode,
      invitePasscode: generatedPasscode,
      shareUrl,
      aiGenerated: Boolean(aiGenerated),
      activityHistory: [
        {
          userId: req.user._id,
          action: 'created_task',
          details: `Task "${title.trim()}" created with ${priority || 'medium'} priority`,
        },
      ],
    });

    await task.save();

    // E. Synchronize Track Progress
    if (trackId) {
      await recalculateTrackProgress(trackId);
    }

    await ActivityLog.create({
      user: req.user._id,
      action: 'created_task',
      entityType: 'task',
      entityId: task._id,
      trackId: trackId || null,
      details: `Created task "${title.trim()}"`,
    });

    const populated = await Task.findById(task._id)
      .populate('creator', 'displayName username avatarUrl')
      .populate('trackId', 'title progress')
      .populate('collaborators.user', 'displayName username avatarUrl');

    return res.status(201).json({
      success: true,
      message: 'Task created and scheduled successfully',
      task: populated,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Toggle Task Status (One-time or Specific Recurring Occurrence)
exports.toggleTaskStatus = async (req, res) => {
  try {
    const { taskId } = req.params;
    const { occurrenceDate } = req.body; // "YYYY-MM-DD"
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    const repeatType = task.repeatConfig?.type || 'none';
    const dateStr = occurrenceDate || new Date().toISOString().split('T')[0];

    let newStatus = 'completed';
    let pointsAwarded = 0;

    if (repeatType !== 'none') {
      // Recurring task: manage individual occurrence so completing one occurrence does not complete all future ones!
      const occIndex = task.completedOccurrences.findIndex((o) => o.dateStr === dateStr);
      if (occIndex > -1) {
        // Reopen this occurrence
        task.completedOccurrences.splice(occIndex, 1);
        newStatus = 'pending';
      } else {
        // Complete this occurrence
        task.completedOccurrences.push({
          dateStr,
          completedAt: new Date(),
          userId: req.user._id,
        });
        newStatus = 'completed';
        pointsAwarded = 10;
      }
    } else {
      // One-time task
      newStatus = task.status === 'completed' ? 'pending' : 'completed';
      task.status = newStatus;
      task.completedAt = newStatus === 'completed' ? new Date() : null;

      if (newStatus === 'completed' && task.pointsEarned === 0) {
        pointsAwarded = 10;
        task.pointsEarned = pointsAwarded;
      }
    }

    if (pointsAwarded > 0) {
      await User.findByIdAndUpdate(req.user._id, { $inc: { points: pointsAwarded } });
      await PointTransaction.create({
        user: req.user._id,
        points: pointsAwarded,
        reason: 'task_completed',
        referenceId: task._id,
        referenceModel: 'Task',
        description: `Completed task occurrence: "${task.title}"`,
      });
    }

    task.activityHistory.push({
      userId: req.user._id,
      action: newStatus === 'completed' ? 'completed_task' : 'reopened_task',
      details: `Occurrence on ${dateStr} marked as ${newStatus}`,
    });

    await task.save();

    if (task.trackId) {
      await recalculateTrackProgress(task.trackId);
    }

    return res.status(200).json({
      success: true,
      task,
      status: newStatus,
      pointsAwarded,
      occurrenceDate: dateStr,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Get Task Details ("More to Know")
exports.getTaskDetails = async (req, res) => {
  try {
    const { taskId } = req.params;
    const task = await Task.findById(taskId)
      .populate('creator', 'displayName username avatarUrl email')
      .populate('assignedTo', 'displayName username avatarUrl')
      .populate('collaborators.user', 'displayName username avatarUrl')
      .populate('trackId', 'title progress startDate endDate milestones')
      .populate('groupConversationId', 'name members')
      .populate('activityHistory.userId', 'displayName username avatarUrl')
      .populate('comments.userId', 'displayName username avatarUrl');

    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
    return res.status(200).json({ success: true, task });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. Update Task
exports.updateTask = async (req, res) => {
  try {
    const { taskId } = req.params;
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    Object.assign(task, req.body);
    task.activityHistory.push({
      userId: req.user._id,
      action: 'updated_task',
      details: 'Task details updated',
    });

    await task.save();
    if (task.trackId) await recalculateTrackProgress(task.trackId);

    const updated = await Task.findById(taskId)
      .populate('creator', 'displayName username avatarUrl')
      .populate('trackId', 'title progress');

    return res.status(200).json({ success: true, task: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 6. Delete Task
exports.deleteTask = async (req, res) => {
  try {
    const { taskId } = req.params;
    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    const trackId = task.trackId;
    await Task.findByIdAndDelete(taskId);

    if (trackId) await recalculateTrackProgress(trackId);

    return res.status(200).json({ success: true, message: 'Task deleted successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
