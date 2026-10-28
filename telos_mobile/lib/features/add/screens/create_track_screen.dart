import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/track_provider.dart';
import '../widgets/planning_flowchart.dart';

class CreateTrackScreen extends StatefulWidget {
  final int initialTab;
  const CreateTrackScreen({super.key, this.initialTab = 0});

  @override
  State<CreateTrackScreen> createState() => _CreateTrackScreenState();
}

class _CreateTrackScreenState extends State<CreateTrackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual Creation Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _visibility = 'private';
  String _category = 'productivity';

  // Dynamic Milestones & Tasks list for manual creation
  final List<String> _milestones = ['Foundation Milestone', 'Mid-Sprint Review', 'Final Delivery'];
  final List<Map<String, String>> _manualTasks = [
    {'title': 'Kickoff & Resource Mapping', 'day': '1'},
    {'title': 'Core Sprint Execution', 'day': '10'},
  ];

  // AI Generation Controllers
  final _aiPromptController = TextEditingController();
  bool _isAiGenerating = false;
  Map<String, dynamic>? _aiGeneratedTrack;

  bool _showFlowchart = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveManual() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Track title')));
      return;
    }

    setState(() => _isSaving = true);

    final trackProvider = context.read<TrackProvider>();
    final trackData = {
      'title': title,
      'description': _descController.text.trim(),
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'visibility': _visibility,
      'category': _category,
      'milestones': _milestones.map((m) => {'title': m, 'targetDate': _endDate.toIso8601String()}).toList(),
      'tasks': _manualTasks.map((t) => {'title': t['title'], 'scheduledDate': _startDate.toIso8601String()}).toList(),
    };

    final success = await trackProvider.createTrack(trackData);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Track "$title" created successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Track'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'MANUAL CREATION'),
            Tab(text: 'AI-GENERATED TRACK'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Manual Creation Tab
          _buildManualCreationTab(),

          // 2. AI-Generated Track Tab
          _buildAiGenerationTab(),
        ],
      ),
    );
  }

  Widget _buildManualCreationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Track Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. 30-Day App Launch Roadmap',
              prefixIcon: Icon(Icons.route_rounded),
            ),
          ),

          const SizedBox(height: 16),

          const Text('Description & Mission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Explain the purpose and outcome of this Track...',
            ),
          ),

          const SizedBox(height: 20),

          // Date Duration
          const Text('Track Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime(2035));
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  icon: const Icon(Icons.play_circle_outline, size: 16),
                  label: Text(DateFormat('MMM d, y').format(_startDate), style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2035));
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: Text(DateFormat('MMM d, y').format(_endDate), style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Visibility & Category
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _visibility,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('Private Track')),
                    DropdownMenuItem(value: 'public', child: Text('Public Track')),
                  ],
                  onChanged: (val) => setState(() => _visibility = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'productivity', child: Text('Productivity')),
                    DropdownMenuItem(value: 'academic', child: Text('Academic')),
                    DropdownMenuItem(value: 'project', child: Text('Project')),
                    DropdownMenuItem(value: 'fitness', child: Text('Fitness')),
                  ],
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.darkBorder),
          const SizedBox(height: 16),

          // Milestones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Track Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Milestone'),
                onPressed: () {
                  setState(() => _milestones.add('Milestone ${_milestones.length + 1}'));
                },
              ),
            ],
          ),
          ..._milestones.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // Visual Flowchart Toggle
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_tree_outlined, color: AppColors.accentCyan),
            title: const Text('View Planning Flowchart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Inspect hierarchy: Goal → Milestones → Tasks', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            trailing: Switch(
              value: _showFlowchart,
              activeColor: AppColors.accentCyan,
              onChanged: (val) => setState(() => _showFlowchart = val),
            ),
          ),

          if (_showFlowchart) ...[
            const SizedBox(height: 8),
            PlanningFlowchart(
              goalTitle: _titleController.text.isNotEmpty ? _titleController.text : 'New Track',
              milestones: _milestones,
              weeks: const ['Week 1 Sprint', 'Week 2 Midpoint', 'Week 3 Polish', 'Week 4 Launch'],
              tasks: _manualTasks.map((t) => t['title']!).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // Save Track Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSaveManual,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Finalize & Create Track', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 2. AI-Generated Track Tab (Specification 7.3 A)
  Widget _buildAiGenerationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentGold.withOpacity(0.12), AppColors.primary.withOpacity(0.12)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Describe your target in plain English. AI will generate a structured Track with milestones, weekly schedules, and daily tasks.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text('Your Goal or Blueprint *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _aiPromptController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Create a 4-week examination preparation plan for advanced organic chemistry with weekend mocks...',
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isAiGenerating
                  ? null
                  : () async {
                      if (_aiPromptController.text.trim().isEmpty) return;
                      setState(() => _isAiGenerating = true);
                      await Future.delayed(const Duration(seconds: 1)); // simulated AI call
                      setState(() {
                        _isAiGenerating = false;
                        _aiGeneratedTrack = {
                          'title': 'Organic Chemistry 4-Week Exam Mastery',
                          'durationWeeks': 4,
                          'milestones': ['Week 1: Reaction Mechanisms', 'Week 2: Synthesis Pathways', 'Week 3: Timed Mocks', 'Week 4: Final Revision'],
                          'tasks': [
                            {'title': 'Map syllabus and reference textbook chapters', 'dayOffset': 1},
                            {'title': 'Solve 40 past paper mechanism questions', 'dayOffset': 5},
                            {'title': 'Full-length timed mock examination 1', 'dayOffset': 14},
                            {'title': 'Targeted error log & formula recap', 'dayOffset': 26},
                          ],
                        };
                      });
                    },
              icon: const Icon(Icons.psychology_outlined),
              label: _isAiGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Generate AI Track Plan'),
            ),
          ),

          if (_aiGeneratedTrack != null) ...[
            const SizedBox(height: 24),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 16),

            const Text('AI Plan Preview & Approval', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
            const SizedBox(height: 6),
            const Text('Review the generated roadmap. You can edit any details before finalizing.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_aiGeneratedTrack!['title'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_aiGeneratedTrack!['durationWeeks']} Weeks Duration  •  ${(_aiGeneratedTrack!['tasks'] as List).length} Tasks Generated', style: const TextStyle(fontSize: 12, color: AppColors.accentCyan)),
                  const SizedBox(height: 14),

                  const Text('Milestones:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...(_aiGeneratedTrack!['milestones'] as List).map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 14, color: AppColors.emerald),
                            const SizedBox(width: 6),
                            Text(m, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )),

                  const SizedBox(height: 14),
                  const Text('Generated Tasks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...(_aiGeneratedTrack!['tasks'] as List).map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: AppColors.primaryLight),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t['title'], style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                onPressed: () async {
                  final trackProvider = context.read<TrackProvider>();
                  final trackData = {
                    'title': _aiGeneratedTrack!['title'],
                    'description': 'AI generated study plan',
                    'startDate': DateTime.now().toIso8601String(),
                    'endDate': DateTime.now().add(const Duration(days: 28)).toIso8601String(),
                    'visibility': 'private',
                    'category': 'academic',
                    'tasks': _aiGeneratedTrack!['tasks'],
                  };
                  await trackProvider.createTrack(trackData);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Track plan saved into Your Tracks!')));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Approve & Create Track', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
