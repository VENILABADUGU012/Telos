import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/task_provider.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDone = _task.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.rose),
            tooltip: 'Delete Task',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task?'),
                  content: const Text('This task will be permanently removed from your schedule and Tracks.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await taskProvider.deleteTask(_task.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDone ? AppColors.emerald.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDone ? AppColors.emerald.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                    color: isDone ? AppColors.emerald : AppColors.primaryLight,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDone ? 'Completed (+${_task.pointsEarned} pts earned)' : 'Active Task • Pending Completion',
                    style: TextStyle(
                      color: isDone ? AppColors.emerald : AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Task Title
            Text(
              _task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            if (_task.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _task.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 16),

            // Key Information Grid
            const Text(
              'Schedule & Recurrence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Scheduled Date',
              value: DateFormat('EEEE, MMMM d, y').format(_task.scheduledDate),
            ),
            if (_task.scheduledTime != null)
              _buildDetailRow(
                icon: Icons.access_time_outlined,
                label: 'Scheduled Time',
                value: _task.scheduledTime!,
              ),
            if (_task.deadline != null)
              _buildDetailRow(
                icon: Icons.flag_outlined,
                label: 'Hard Deadline',
                value: DateFormat('MMM d, y - h:mm a').format(_task.deadline!),
              ),
            _buildDetailRow(
              icon: Icons.repeat_rounded,
              label: 'Repeat Rule',
              value: _task.repeatType == 'none' ? 'One-time Task' : 'Recurring: ${_task.repeatType.toUpperCase()}',
            ),
            _buildDetailRow(
              icon: Icons.wb_sunny_outlined,
              label: 'All-Day Persistence',
              value: _task.isAllDayUntilComplete ? 'All Day Until Complete (Carries over)' : 'Standard day',
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 16),

            // Context: Track & Collaborators
            const Text(
              'Context & Team',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.route_rounded,
              label: 'Associated Track',
              value: _task.trackTitle ?? 'Standalone (Not part of a Track)',
            ),
            _buildDetailRow(
              icon: Icons.person_outline,
              label: 'Created By',
              value: _task.creatorName,
            ),
            _buildDetailRow(
              icon: Icons.lock_outline,
              label: 'Visibility',
              value: _task.visibility.toUpperCase(),
            ),

            if (_task.collaborators.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Assigned Collaborators:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              ..._task.collaborators.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.accentCyan.withOpacity(0.2),
                          child: Text(c.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.accentCyan)),
                        ),
                        const SizedBox(width: 8),
                        Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(c.role.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 32),

            // Toggle Completion Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? AppColors.darkSurface : AppColors.emerald,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await taskProvider.toggleTaskStatus(_task);
                  setState(() {
                    _task = _task.copyWith(status: isDone ? 'pending' : 'completed');
                  });
                },
                icon: Icon(isDone ? Icons.replay : Icons.check_circle_outline),
                label: Text(
                  isDone ? 'Reopen Task' : 'Mark Task Completed (+10 pts)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
