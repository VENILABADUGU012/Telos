import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PlanningFlowchart extends StatelessWidget {
  final String goalTitle;
  final List<String> milestones;
  final List<String> weeks;
  final List<String> tasks;

  const PlanningFlowchart({
    super.key,
    required this.goalTitle,
    required this.milestones,
    required this.weeks,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Level 1: Overall Goal Node
          _buildNode(
            title: 'GOAL: $goalTitle',
            subtitle: 'Overarching Milestone Objective',
            icon: Icons.flag_rounded,
            color: AppColors.accentGold,
          ),

          _buildConnector(),

          // Level 2: Milestones
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: milestones.map((m) => _buildPillNode(m, Icons.verified_rounded, AppColors.emerald)).toList(),
          ),

          _buildConnector(),

          // Level 3: Weeks Breakdown
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: weeks.map((w) => _buildPillNode(w, Icons.calendar_view_week, AppColors.primaryLight)).toList(),
          ),

          _buildConnector(),

          // Level 4: Concrete Tasks
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tasks.map((t) => _buildPillNode(t, Icons.task_alt, AppColors.accentCyan)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNode({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              children: [
                Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                const SizedBox(height: 2),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillNode(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 2,
      height: 18,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.darkBorder,
    );
  }
}
