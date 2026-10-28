const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const Task = require('../models/Task');
const User = require('../models/User');

// 1. Get User Conversations
exports.getConversations = async (req, res) => {
  try {
    const conversations = await Conversation.find({
      'members.user': req.user._id,
    })
      .populate('members.user', 'displayName username avatarUrl')
      .populate('lastMessage.senderId', 'displayName username')
      .sort({ updatedAt: -1 });

    return res.status(200).json({ success: true, count: conversations.length, conversations });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Create or Get 1-on-1 Conversation
exports.getOrCreateDirectConversation = async (req, res) => {
  try {
    const { recipientId } = req.body;
    if (!recipientId) return res.status(400).json({ success: false, message: 'recipientId is required' });

    let conversation = await Conversation.findOne({
      type: 'individual',
      $and: [
        { 'members.user': req.user._id },
        { 'members.user': recipientId },
      ],
    }).populate('members.user', 'displayName username avatarUrl');

    if (!conversation) {
      conversation = await Conversation.create({
        type: 'individual',
        members: [
          { user: req.user._id, role: 'member' },
          { user: recipientId, role: 'member' },
        ],
      });
      conversation = await Conversation.findById(conversation._id).populate('members.user', 'displayName username avatarUrl');
    }

    return res.status(200).json({ success: true, conversation });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Create Group Conversation
exports.createGroupConversation = async (req, res) => {
  try {
    const { name, avatarUrl, memberIds } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'Group name is required' });

    const members = [{ user: req.user._id, role: 'admin' }];
    if (memberIds && Array.isArray(memberIds)) {
      memberIds.forEach((id) => {
        if (id.toString() !== req.user._id.toString()) {
          members.push({ user: id, role: 'member' });
        }
      });
    }

    const conversation = await Conversation.create({
      type: 'group',
      name,
      avatarUrl: avatarUrl || '',
      members,
    });

    const populated = await Conversation.findById(conversation._id).populate('members.user', 'displayName username avatarUrl');
    return res.status(201).json({ success: true, conversation: populated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Get Messages for Conversation
exports.getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const messages = await Message.find({ conversationId })
      .populate('sender', 'displayName username avatarUrl')
      .populate('reactions.user', 'displayName username')
      .populate('replyTo')
      .sort({ createdAt: 1 });

    return res.status(200).json({ success: true, count: messages.length, messages });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 5. Send Message (Text, Media, Voice, Poll)
exports.sendMessage = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { text, attachments, voiceUrl, voiceDurationSeconds, poll, replyTo } = req.body;

    const message = await Message.create({
      conversationId,
      sender: req.user._id,
      text: text || '',
      attachments: attachments || [],
      voiceUrl: voiceUrl || null,
      voiceDurationSeconds: voiceDurationSeconds || 0,
      poll: poll || undefined,
      replyTo: replyTo || null,
      readBy: [req.user._id],
    });

    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: {
        text: text || (poll ? `📊 Poll: ${poll.question}` : voiceUrl ? '🎤 Voice message' : '📎 Attachment'),
        senderId: req.user._id,
        createdAt: new Date(),
      },
    });

    const populated = await Message.findById(message._id)
      .populate('sender', 'displayName username avatarUrl')
      .populate('replyTo');

    return res.status(201).json({ success: true, message: populated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 6. Vote in Poll
exports.votePoll = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { optionIndex } = req.body;

    const message = await Message.findById(messageId);
    if (!message || !message.poll) return res.status(404).json({ success: false, message: 'Poll message not found' });

    // Remove user's previous votes
    message.poll.options.forEach((opt) => {
      opt.votes = opt.votes.filter((u) => u.toString() !== req.user._id.toString());
    });

    if (message.poll.options[optionIndex]) {
      message.poll.options[optionIndex].votes.push(req.user._id);
    }

    await message.save();
    return res.status(200).json({ success: true, message });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 7. Group Admin Create Task (Directly from Group Chat)
exports.createGroupTask = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { title, description, scheduledDate, deadline, assignedParticipantIds } = req.body;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation || conversation.type !== 'group') {
      return res.status(400).json({ success: false, message: 'Invalid group conversation' });
    }

    // Verify creator is admin
    const member = conversation.members.find((m) => m.user.toString() === req.user._id.toString());
    if (!member || member.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only group admins can create group tasks' });
    }

    const assigned = assignedParticipantIds && assignedParticipantIds.length > 0
      ? assignedParticipantIds
      : conversation.members.map((m) => m.user);

    const task = await Task.create({
      title,
      description: description || `Group Task from ${conversation.name}`,
      scheduledDate: scheduledDate ? new Date(scheduledDate) : new Date(),
      deadline: deadline ? new Date(deadline) : null,
      creator: req.user._id,
      assignedTo: assigned,
      collaborators: assigned.map((id) => ({
        user: id,
        role: id.toString() === req.user._id.toString() ? 'admin' : 'member',
        joined: true,
        completed: false,
      })),
      groupConversationId: conversation._id,
    });

    // Add to group task list
    conversation.groupTasks.push(task._id);
    await conversation.save();

    // Send announcement message in group chat
    await Message.create({
      conversationId,
      sender: req.user._id,
      text: `📋 Group Admin assigned a new task: "${title}". Assigned to ${assigned.length} members.`,
    });

    return res.status(201).json({ success: true, task });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 8. Group Admin Task Monitoring
exports.getGroupTaskMonitoring = async (req, res) => {
  try {
    const { taskId } = req.params;
    const task = await Task.findById(taskId)
      .populate('creator', 'displayName username avatarUrl')
      .populate('assignedTo', 'displayName username avatarUrl')
      .populate('collaborators.user', 'displayName username avatarUrl');

    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    const totalAssigned = task.assignedTo.length;
    const completedList = task.collaborators.filter((c) => c.completed).map((c) => c.user);
    const pendingList = task.collaborators.filter((c) => !c.completed).map((c) => c.user);

    return res.status(200).json({
      success: true,
      task,
      totalAssigned,
      completedCount: completedList.length,
      pendingCount: pendingList.length,
      completedList,
      pendingList,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
