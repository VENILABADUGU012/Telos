import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'create_task_screen.dart';
import 'create_track_screen.dart';

class AddHubScreen extends StatelessWidget {
  const AddHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE NEW'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What would you like to build?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select an action below to schedule a standalone task, plan a structured Track, or leverage AI roadmaps.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // Option 1: Create Task
            _buildActionCard(
              context: context,
              icon: Icons.check_box_outlined,
              title: 'Create Task',
              subtitle: 'Schedule a single or recurring task with deadlines, reminders, and track assignment.',
              gradient: const [AppColors.primary, Color(0xFF4F46E5)],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
              },
            ),

            const SizedBox(height: 14),

            // Option 2: Create Track
            _buildActionCard(
              context: context,
              icon: Icons.alt_route_rounded,
              title: 'Create Track',
              subtitle: 'Design a comprehensive long-term roadmap with weekly milestones, flowchart planning, and collaboration.',
              gradient: const [AppColors.accentCyan, Color(0xFF0284C7)],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTrackScreen()),
                );
              },
            ),

            const SizedBox(height: 14),

            // Option 3: Calendar-Based Task Creation
            _buildActionCard(
              context: context,
              icon: Icons.calendar_month_outlined,
              title: 'Calendar-Based Task Creation',
              subtitle: 'Pick any date on the interactive calendar to instantly schedule work for that day.',
              gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CreateTaskScreen(initialDate: picked)),
                  );
                }
              },
            ),

            const SizedBox(height: 14),

            // Option 4: AI Track Generation
            _buildActionCard(
              context: context,
              icon: Icons.auto_awesome,
              title: 'AI-Generated Track',
              subtitle: 'Describe your goal in plain English (e.g. "4-week exam prep") and let AI structure the entire roadmap.',
              gradient: const [AppColors.accentGold, Color(0xFFD97706)],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTrackScreen(initialTab: 1)),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
