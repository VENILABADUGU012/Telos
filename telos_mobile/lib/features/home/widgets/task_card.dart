import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_model.dart';
import '../screens/task_details_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isDone ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDone ? AppColors.darkBorder.withOpacity(0.5) : AppColors.darkBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completion Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.emerald : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isDone ? AppColors.emerald : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),

                  // Task Title & Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDone ? AppColors.textMuted : AppColors.textLight,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.emerald.withOpacity(0.15)
                          : task.isInProgress
                              ? AppColors.accentCyan.withOpacity(0.15)
                              : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isDone
                          ? 'Completed'
                          : task.isInProgress
                              ? 'In Progress'
                              : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDone
                            ? AppColors.emerald
                            : task.isInProgress
                                ? AppColors.accentCyan
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.darkBorder),
              const SizedBox(height: 10),

              // Bottom Details Row: Time, Track tag, Collaborators, "More to Know"
              Row(
                children: [
                  // Scheduled Time / Deadline
                  if (task.scheduledTime != null) ...[
                    const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      task.scheduledTime!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Associated Track badge if linked
                  if (task.trackTitle != null) ...[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.trackTitle!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Collaborator avatars
                  if (task.collaborators.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.group_outlined, size: 14, color: AppColors.accentCyan),
                        const SizedBox(width: 4),
                        Text(
                          '${task.collaborators.length}',
                          style: const TextStyle(fontSize: 12, color: AppColors.accentCyan),
                        ),
                      ],
                    ),

                  const Spacer(),

                  // "More to Know" Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskDetailsScreen(task: task),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'More to Know',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.primaryLight),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
