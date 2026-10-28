import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/track_model.dart';
import 'track_chat_screen.dart';

class TrackDetailsScreen extends StatefulWidget {
  final TrackModel track;
  final String initialSection;

  const TrackDetailsScreen({
    super.key,
    required this.track,
    this.initialSection = 'analytics',
  });

  @override
  State<TrackDetailsScreen> createState() => _TrackDetailsScreenState();
}

class _TrackDetailsScreenState extends State<TrackDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _aiPromptController = TextEditingController();
  bool _aiGenerating = false;
  String? _aiProposedPreview;

  final List<String> _sections = [
    'analytics',
    'tasks',
    'weekly',
    'monthly',
    'timeline',
    'ai_edit',
  ];

  @override
  void initState() {
    super.initState();
    int initialIdx = _sections.indexOf(widget.initialSection);
    if (initialIdx == -1) initialIdx = 0;
    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIdx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return Scaffold(
      appBar: AppBar(
        title: Text(track.title),
        actions: [
          // Track Chat Action (Isolated Room)
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accentCyan),
            tooltip: 'Track Chat Room',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackChatScreen(trackId: track.id, trackTitle: track.title),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'ANALYTICS'),
            Tab(text: 'DAILY TASKS'),
            Tab(text: 'WEEKLY'),
            Tab(text: 'MONTHLY'),
            Tab(text: 'TIMELINE'),
            Tab(text: 'AI EDIT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // A. Overall Analytics
          _buildAnalyticsTab(track),

          // B. Day-to-Day Tasks
          _buildDayToDayTasksTab(track),

          // C. Weekly Task Allotment
          _buildWeeklyTab(track),

          // D. Monthly Task Allotment
          _buildMonthlyTab(track),

          // E. Collaborator Timeline
          _buildTimelineTab(track),

          // G. AI-Assisted Track Editing
          _buildAiEditTab(track),
        ],
      ),
    );
  }

  // A. Overall Analytics Tab
  Widget _buildAnalyticsTab(TrackModel track) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Track Completion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${track.progressPercentage}% Complete', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                  Text('${track.completedTasks}/${track.totalTasks} Tasks Done', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: track.progressPercentage / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.darkSurface,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Milestones
        const Text('Track Milestones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (track.milestones.isEmpty)
          const Text('No milestones set yet.', style: TextStyle(color: AppColors.textMuted))
        else
          ...track.milestones.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      m.completed ? Icons.check_circle : Icons.circle_outlined,
                      color: m.completed ? AppColors.emerald : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: m.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(m.targetDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // B. Day-to-Day Tasks
  Widget _buildDayToDayTasksTab(TrackModel track) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Chronological Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Task'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTaskTile('Phase 1: Foundation & Setup', 'Day 1 • Completed', true),
        _buildTaskTile('Core Data Pipeline Architecture', 'Day 5 • Completed', true),
        _buildTaskTile('Mid-Sprint Evaluation Drill', 'Day 12 • Scheduled', false),
        _buildTaskTile('Final Integration & Retrospective', 'Day 28 • Pending', false),
      ],
    );
  }

  Widget _buildTaskTile(String title, String subtitle, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? AppColors.emerald : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, decoration: isDone ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // C. Weekly Allotment Tab
  Widget _buildWeeklyTab(TrackModel track) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Weekly Sprint Allotment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildWeekCard('Week 1: Baseline Architecture', '3 tasks • 100% complete', 1.0),
        _buildWeekCard('Week 2: Feature Development', '4 tasks • 50% complete', 0.5),
        _buildWeekCard('Week 3: Stress Testing & Optimization', '3 tasks • Upcoming', 0.0),
        _buildWeekCard('Week 4: Final Release Milestone', '2 tasks • Upcoming', 0.0),
      ],
    );
  }

  Widget _buildWeekCard(String title, String subtitle, double progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.darkSurface,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // D. Monthly Allotment Tab
  Widget _buildMonthlyTab(TrackModel track) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Monthly Goal Allotment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Month 1 Goals: MVP Execution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
              SizedBox(height: 8),
              Text('• Complete all core infrastructure milestones\n• Execute bi-weekly reviews with collaborators\n• Maintain 80%+ consistency on daily sprint habits', style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // E. Collaborator Timeline
  Widget _buildTimelineTab(TrackModel track) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Collaborators Timeline & Audit History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildTimelineItem('Venil (Owner)', 'Completed task: System Architecture & Schemas', '2 hours ago', Icons.check_circle_outline, AppColors.emerald),
        _buildTimelineItem('Elena Rostova', 'Added milestone: Production Deployment Checklist', 'Yesterday', Icons.add_circle_outline, AppColors.primaryLight),
        _buildTimelineItem('System', 'Track created from Full-Stack Roadmap Template', '5 days ago', Icons.rocket_launch_outlined, AppColors.accentCyan),
      ],
    );
  }

  Widget _buildTimelineItem(String user, String action, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(action, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // G. AI-Assisted Track Editing
  Widget _buildAiEditTab(TrackModel track) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('AI-Assisted Plan Modification', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Describe how you want to adjust this Track in natural language (e.g. "Add 3 revision tasks to Week 3", "Move unfinished tasks to next week", "Redistribute tasks to meet deadline").',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _aiPromptController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Add 2 revision sessions in week 2 and set deadlines for Friday...',
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _aiGenerating
                ? null
                : () async {
                    if (_aiPromptController.text.trim().isEmpty) return;
                    setState(() => _aiGenerating = true);
                    await Future.delayed(const Duration(seconds: 1)); // simulated AI processing
                    setState(() {
                      _aiGenerating = false;
                      _aiProposedPreview =
                          'Proposed Changes for "${track.title}":\n'
                          '1. Added "Mid-Sprint Diagnostic Drill" on ${DateFormat('MMM d').format(DateTime.now().add(const Duration(days: 4)))}\n'
                          '2. Added "Formulas & Weak Areas Review" on ${DateFormat('MMM d').format(DateTime.now().add(const Duration(days: 8)))}\n'
                          '3. Recalculated total tasks from ${track.totalTasks} to ${track.totalTasks + 2}.';
                    });
                  },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: _aiGenerating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Preview AI Adjustments'),
          ),
        ),

        if (_aiProposedPreview != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.preview_rounded, size: 18, color: AppColors.accentCyan),
                    SizedBox(width: 8),
                    Text('Proposed Preview (Review Before Applying)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentCyan)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_aiProposedPreview!, style: const TextStyle(fontSize: 13, height: 1.5)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _aiProposedPreview = null),
                      child: const Text('Discard', style: TextStyle(color: AppColors.rose)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI Plan updates applied successfully!')),
                        );
                        setState(() => _aiProposedPreview = null);
                      },
                      child: const Text('Confirm & Apply Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
