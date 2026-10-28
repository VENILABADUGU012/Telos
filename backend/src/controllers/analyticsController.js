const Task = require('../models/Task');
const Track = require('../models/Track');
const PointTransaction = require('../models/PointTransaction');

exports.getAnalytics = async (req, res) => {
  try {
    const { period = 'weekly' } = req.query; // 'weekly', 'monthly', 'yearly'
    const now = new Date();
    let startDate = new Date();

    if (period === 'weekly') {
      startDate.setDate(now.getDate() - 7);
    } else if (period === 'monthly') {
      startDate.setMonth(now.getMonth() - 1);
    } else if (period === 'yearly') {
      startDate.setFullYear(now.getFullYear() - 1);
    }

    // 1. Task metrics in range
    const userTasks = await Task.find({
      $or: [{ creator: req.user._id }, { assignedTo: req.user._id }],
      scheduledDate: { $gte: startDate, $lte: now },
    });

    const totalScheduled = userTasks.length;
    const completedTasks = userTasks.filter((t) => t.status === 'completed').length;
    const inProgressTasks = userTasks.filter((t) => t.status === 'in_progress').length;
    const pendingTasks = userTasks.filter((t) => t.status === 'pending').length;
    const completionPercentage = totalScheduled > 0 ? Math.round((completedTasks / totalScheduled) * 100) : 0;

    // 2. Track comparisons
    const tracks = await Track.find({
      $or: [{ creator: req.user._id }, { 'collaborators.user': req.user._id }],
    }).select('title progress category startDate endDate');

    const overallTrackProgress =
      tracks.length > 0
        ? Math.round(tracks.reduce((acc, t) => acc + (t.progress?.percentage || 0), 0) / tracks.length)
        : 0;

    // 3. Points earned in this period
    const pointTransactions = await PointTransaction.find({
      user: req.user._id,
      createdAt: { $gte: startDate, $lte: now },
    });

    const pointsEarnedPeriod = pointTransactions.reduce((acc, curr) => acc + curr.points, 0);

    // 4. Daily completion trends (e.g. last 7 intervals)
    const trends = [];
    const intervalDays = period === 'weekly' ? 1 : period === 'monthly' ? 4 : 30;
    const totalSlots = 7;

    for (let i = totalSlots - 1; i >= 0; i--) {
      const slotEnd = new Date(now);
      slotEnd.setDate(slotEnd.getDate() - i * intervalDays);
      const slotStart = new Date(slotEnd);
      slotStart.setDate(slotStart.getDate() - intervalDays);

      const count = userTasks.filter(
        (t) => t.status === 'completed' && t.completedAt && t.completedAt >= slotStart && t.completedAt <= slotEnd
      ).length;

      trends.push({
        label: slotEnd.toLocaleDateString('en-US', { weekday: 'short', month: 'numeric', day: 'numeric' }),
        completedCount: count,
      });
    }

    return res.status(200).json({
      success: true,
      period,
      metrics: {
        totalScheduled,
        completedTasks,
        inProgressTasks,
        pendingTasks,
        completionPercentage,
        overallTrackProgress,
        pointsEarnedPeriod,
      },
      tracksComparison: tracks.map((t) => ({
        trackId: t._id,
        title: t.title,
        progress: t.progress?.percentage || 0,
        completed: t.progress?.completedTasks || 0,
        total: t.progress?.totalTasks || 0,
        category: t.category,
      })),
      trends,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
