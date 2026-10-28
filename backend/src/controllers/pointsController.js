const PointTransaction = require('../models/PointTransaction');
const User = require('../models/User');

exports.getPointsChest = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const now = new Date();
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(now.getDate() - 7);

    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(now.getMonth() - 1);

    const [weeklyTransactions, monthlyTransactions, allTransactions] = await Promise.all([
      PointTransaction.find({ user: req.user._id, createdAt: { $gte: oneWeekAgo } }),
      PointTransaction.find({ user: req.user._id, createdAt: { $gte: oneMonthAgo } }),
      PointTransaction.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(20),
    ]);

    const pointsThisWeek = weeklyTransactions.reduce((acc, t) => acc + t.points, 0);
    const pointsThisMonth = monthlyTransactions.reduce((acc, t) => acc + t.points, 0);

    const achievementsList = [
      { id: 'first_step', title: 'Initiator', description: 'Created your first Track', unlocked: user.points >= 50 },
      { id: 'task_slayer', title: 'Task Slayer', description: 'Completed 10 tasks', unlocked: user.points >= 150 },
      { id: 'consistency_king', title: 'Unstoppable Momentum', description: 'Earned 300+ points', unlocked: user.points >= 300 },
      { id: 'master_planner', title: 'Grand Strategist', description: 'Reached 500+ points and multiple milestones', unlocked: user.points >= 500 },
    ];

    return res.status(200).json({
      success: true,
      currentBalance: user.points || 0,
      pointsThisWeek,
      pointsThisMonth,
      streakDays: user.streakDays || 1,
      recentActivity: allTransactions,
      achievements: achievementsList,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};
