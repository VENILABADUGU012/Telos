import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/rewards_provider.dart';

class PointsChestScreen extends StatefulWidget {
  const PointsChestScreen({super.key});

  @override
  State<PointsChestScreen> createState() => _PointsChestScreenState();
}

class _PointsChestScreenState extends State<PointsChestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardsProvider>().fetchRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Points Chest'),
      ),
      body: RefreshIndicator(
        onRefresh: () => rewards.fetchRewards(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Chest Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.military_tech_rounded, size: 52, color: AppColors.accentGold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${rewards.balance}',
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const Text('Total Accumulated TELOS Points', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('This Week', '+${rewards.pointsThisWeek} pts'),
                      _buildMiniStat('This Month', '+${rewards.pointsThisMonth} pts'),
                      _buildMiniStat('Streak', '${rewards.streakDays} Days 🔥'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievements Section
            const Text('Milestones & Achievements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...rewards.achievements.map((a) {
              final unlocked = a['unlocked'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked ? AppColors.accentGold.withOpacity(0.4) : AppColors.darkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: unlocked ? AppColors.accentGold.withOpacity(0.15) : AppColors.darkSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                        color: unlocked ? AppColors.accentGold : AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: unlocked ? AppColors.textLight : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a['description']!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (unlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('UNLOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Recent Point Ledger
            const Text('Recent Points Ledger', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...rewards.recentActivity.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.emerald, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item['description'] ?? 'Points activity', style: const TextStyle(fontSize: 13)),
                      ),
                      Text('+${item['points']} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
