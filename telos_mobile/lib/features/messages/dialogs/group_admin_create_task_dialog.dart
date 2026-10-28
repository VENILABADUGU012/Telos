import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class GroupAdminCreateTaskDialog extends StatefulWidget {
  final String conversationId;
  final Function(Map<String, dynamic>) onTaskCreated;

  const GroupAdminCreateTaskDialog({
    super.key,
    required this.conversationId,
    required this.onTaskCreated,
  });

  @override
  State<GroupAdminCreateTaskDialog> createState() => _GroupAdminCreateTaskDialogState();
}

class _GroupAdminCreateTaskDialogState extends State<GroupAdminCreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));

  final List<String> _selectedMembers = ['Alex Rivera', 'Elena Rostova', 'Marcus Cole'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Assign Group Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Production Deployment Checklist'),
            ),
            const SizedBox(height: 14),

            const Text('Deadline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text(DateFormat('MMM d, y').format(_deadline)),
            ),
            const SizedBox(height: 14),

            const Text('Assigned Participants:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _selectedMembers.map((m) => Chip(
                label: Text(m, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.darkSurface,
                side: const BorderSide(color: AppColors.darkBorder),
              )).toList(),
            ),
            const SizedBox(height: 8),
            const Text(
              'This task will automatically appear on all assigned members\' Home dashboards.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            widget.onTaskCreated({
              'title': _titleController.text.trim(),
              'description': _descController.text.trim(),
              'deadline': _deadline.toIso8601String(),
              'scheduledDate': DateTime.now().toIso8601String(),
            });
            Navigator.pop(context);
          },
          child: const Text('Assign & Share in Group'),
        ),
      ],
    );
  }
}
