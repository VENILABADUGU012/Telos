const Task = require('../models/Task');
const Track = require('../models/Track');
const User = require('../models/User');

// Helper to formulate intelligent response based on actual user context
exports.chatWithAI = async (req, res) => {
  try {
    const { message, conversationHistory } = req.body;
    if (!message) return res.status(400).json({ success: false, message: 'Message is required' });

    const queryLower = message.toLowerCase();

    // 1. Fetch authorized live user context
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const [todayTasks, allTracks, overdueTasks, user] = await Promise.all([
      Task.find({
        $or: [{ creator: req.user._id }, { assignedTo: req.user._id }],
        scheduledDate: { $gte: today, $lt: tomorrow },
      }),
      Track.find({
        $or: [{ creator: req.user._id }, { 'collaborators.user': req.user._id }],
      }),
      Task.find({
        $or: [{ creator: req.user._id }, { assignedTo: req.user._id }],
        status: { $ne: 'completed' },
        deadline: { $lt: new Date() },
      }),
      User.findById(req.user._id),
    ]);

    let reply = '';
    let suggestedActions = [];
    let generatedPlan = null;

    // A. Detect plan generation request (e.g. "Create a 4-week...", "plan my...", "study plan")
    if (
      queryLower.includes('plan') ||
      queryLower.includes('roadmap') ||
      queryLower.includes('track') ||
      queryLower.includes('routine') ||
      queryLower.includes('prepare')
    ) {
      const durationWeeks = queryLower.includes('month') ? 4 : queryLower.includes('week') ? 2 : 4;
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(startDate.getDate() + durationWeeks * 7);

      // Generate intelligent structured plan
      let planTitle = 'Goal Sprint';
      if (queryLower.includes('study') || queryLower.includes('exam')) planTitle = 'Comprehensive Exam & Mastery Track';
      else if (queryLower.includes('fitness') || queryLower.includes('workout')) planTitle = 'Peak Physical Conditioning & Habit Track';
      else if (queryLower.includes('project') || queryLower.includes('code') || queryLower.includes('app')) planTitle = 'Software Engineering & Launch Track';
      else planTitle = `Focused 4-Week Milestone Plan`;

      const generatedTasks = [
        {
          title: `Phase 1: Foundation & Requirements Analysis`,
          description: `Map out all resources, clear blocker tasks, and establish working routine.`,
          dayOffset: 1,
          scheduledDate: new Date(startDate.getTime() + 1 * 86400000).toISOString().split('T')[0],
          deadline: new Date(startDate.getTime() + 3 * 86400000).toISOString().split('T')[0],
        },
        {
          title: `Phase 2: Core Execution & Deep Work Sprint`,
          description: `Execute high-priority items with daily focused blocks.`,
          dayOffset: 7,
          scheduledDate: new Date(startDate.getTime() + 7 * 86400000).toISOString().split('T')[0],
          deadline: new Date(startDate.getTime() + 10 * 86400000).toISOString().split('T')[0],
        },
        {
          title: `Phase 3: Mid-Point Assessment & Iteration`,
          description: `Review metrics, eliminate bottlenecks, and re-tune remaining targets.`,
          dayOffset: 14,
          scheduledDate: new Date(startDate.getTime() + 14 * 86400000).toISOString().split('T')[0],
          deadline: new Date(startDate.getTime() + 16 * 86400000).toISOString().split('T')[0],
        },
        {
          title: `Phase 4: Final Sprint, Polish & Launch`,
          description: `Complete all outstanding tasks, conduct final tests, and celebrate milestone.`,
          dayOffset: 21,
          scheduledDate: new Date(startDate.getTime() + 21 * 86400000).toISOString().split('T')[0],
          deadline: new Date(startDate.getTime() + 28 * 86400000).toISOString().split('T')[0],
        },
      ];

      const milestones = [
        { title: 'Kickoff & Baseline Verified', targetDate: new Date(startDate.getTime() + 3 * 86400000) },
        { title: '50% Core Milestones Completed', targetDate: new Date(startDate.getTime() + 14 * 86400000) },
        { title: '100% Sprint Goal Achieved', targetDate: endDate },
      ];

      generatedPlan = {
        title: planTitle,
        description: `Structured AI-crafted roadmap based on your request: "${message}".`,
        durationWeeks,
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
        milestones,
        tasks: generatedTasks,
      };

      reply = `I have generated a structured **${planTitle}** spanning ${durationWeeks} weeks with ${generatedTasks.length} milestones and tasks. Please review the interactive preview below. You can customize dates, edit individual tasks, and approve it to create a new Track or merge it into an existing one.`;
      suggestedActions = ['Preview Plan', 'Adjust Durations', 'Ask Follow-up'];
    }
    // B. Questions about today's tasks
    else if (queryLower.includes('today') || queryLower.includes('schedule') || queryLower.includes('what do i have')) {
      if (todayTasks.length === 0) {
        reply = `You currently have **0 tasks scheduled for today**. Would you like to schedule high-priority tasks or explore your active Tracks?`;
        suggestedActions = ['Schedule a Task', 'View Active Tracks', 'Ask AI to plan my day'];
      } else {
        const completedCount = todayTasks.filter((t) => t.status === 'completed').length;
        reply = `You have **${todayTasks.length} task(s)** scheduled for today (${completedCount} completed, ${todayTasks.length - completedCount} pending):\n` +
          todayTasks.map((t) => `• ${t.status === 'completed' ? '✅' : '⏳'} **${t.title}** ${t.scheduledTime ? `at ${t.scheduledTime}` : ''}`).join('\n');
        suggestedActions = ['Prioritize pending tasks', 'Add a new task'];
      }
    }
    // C. Overdue tasks
    else if (queryLower.includes('overdue') || queryLower.includes('behind') || queryLower.includes('delayed')) {
      if (overdueTasks.length === 0) {
        reply = `Great news! You have **no overdue tasks**. All your scheduled commitments are on track.`;
      } else {
        reply = `You have **${overdueTasks.length} overdue task(s)** that need attention:\n` +
          overdueTasks.map((t) => `• ⚠️ **${t.title}** (Deadline was ${new Date(t.deadline).toLocaleDateString()})`).join('\n') +
          `\n\nWould you like me to help you reschedule these to an upcoming available window?`;
        suggestedActions = ['Reschedule overdue tasks', 'Reprioritize day'];
      }
    }
    // D. Tracks and progress
    else if (queryLower.includes('track') || queryLower.includes('progress') || queryLower.includes('points')) {
      reply = `Here is your current TELOS status:\n` +
        `• **Active Tracks:** ${allTracks.length}\n` +
        `• **Accumulated Points:** ${user?.points || 0} pts\n` +
        (allTracks.length > 0
          ? allTracks.map((t) => `  - **${t.title}**: ${t.progress?.percentage || 0}% complete (${t.progress?.completedTasks || 0}/${t.progress?.totalTasks || 0} tasks)`).join('\n')
          : `• No active tracks created yet.`);
      suggestedActions = ['Create new Track', 'View Points Chest'];
    }
    // General helpful assistant response
    else {
      reply = `I am your TELOS AI Planning Assistant. I can help you inspect your schedule, reprioritize overdue work, analyze your track progress, or generate full structured roadmaps.\n\nTry asking:\n• *"What should I prioritize today?"*\n• *"Create a 4-week exam prep track"*\n• *"Which tracks are falling behind?"*`;
      suggestedActions = ['What tasks do I have today?', 'Create a 4-week study plan', 'How many points do I have?'];
    }

    return res.status(200).json({
      success: true,
      reply,
      suggestedActions,
      generatedPlan,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
