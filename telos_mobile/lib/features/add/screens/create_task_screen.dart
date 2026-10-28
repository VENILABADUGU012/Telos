import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/track_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  final DateTime? initialDate;
  const CreateTaskScreen({super.key, this.initialDate});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _collaboratorNameController = TextEditingController();
  final _customRoleController = TextEditingController();
  final _customIntervalController = TextEditingController(text: '2');

  // Priority
  String _priority = 'medium'; // 'low' | 'medium' | 'high' | 'urgent'

  // Date & Time
  late DateTime _scheduledDate;
  TimeOfDay? _scheduledTime;
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;

  // Flags
  bool _isAllDay = false;
  bool _isAllDayUntilComplete = false;

  // Recurrence
  String _repeatType = 'none'; // 'none' | 'daily' | 'weekdays' | 'weekly' | 'monthly' | 'custom' | 'repeat_until_completed'
  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5}; // 1 = Mon, 7 = Sun
  DateTime? _repeatStartDate;
  DateTime? _repeatEndDate;

  // Attachments
  final List<Map<String, dynamic>> _attachments = [];

  // Track Association
  String? _selectedTrackId;

  // Collaborators
  final List<Map<String, String>> _collaborators = [];
  String _selectedRole = 'member';

  // Visibility & Invitation
  String _visibility = 'private'; // 'private' | 'public'
  late String _invitePasscode;
  late String _shareUrl;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _scheduledDate = widget.initialDate ?? DateTime.now();
    _repeatStartDate = _scheduledDate;
    _generateInviteSecrets();
  }

  void _generateInviteSecrets() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final code = List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
    _invitePasscode = 'TL-$code';
    _shareUrl = 'https://telos.app/join/task/$code';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _collaboratorNameController.dispose();
    _customRoleController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Date & Deadline Validation
    DateTime? fullDeadline;
    if (_deadlineDate != null) {
      fullDeadline = DateTime(
        _deadlineDate!.year,
        _deadlineDate!.month,
        _deadlineDate!.day,
        _deadlineTime?.hour ?? 23,
        _deadlineTime?.minute ?? 59,
      );

      final fullScheduled = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime?.hour ?? 0,
        _scheduledTime?.minute ?? 0,
      );

      if (fullDeadline.isBefore(fullScheduled)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.rose,
            content: Text('Error: Hard deadline cannot be set earlier than the scheduled date/time.'),
          ),
        );
        return;
      }
    }

    // Recurrence End Date Validation
    if (_repeatType != 'none' && _repeatEndDate != null && _repeatEndDate!.isBefore(_scheduledDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.rose,
          content: Text('Error: Repeat end date cannot be earlier than scheduled start date.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final taskProvider = context.read<TaskProvider>();
    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'priority': _priority,
      'scheduledDate': _scheduledDate.toIso8601String(),
      'scheduledTime': _scheduledTime != null
          ? '${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'isAllDay': _isAllDay,
      'isAllDayUntilComplete': _isAllDayUntilComplete,
      'deadline': fullDeadline?.toIso8601String(),
      'repeatConfig': {
        'type': _repeatType,
        'selectedDays': _repeatType == 'weekdays' ? _selectedWeekdays.toList() : [],
        'startDate': _repeatStartDate?.toIso8601String(),
        'endDate': _repeatEndDate?.toIso8601String(),
        'customIntervalDays': int.tryParse(_customIntervalController.text) ?? 2,
      },
      'attachments': _attachments,
      'trackId': _selectedTrackId,
      'collaborators': _collaborators.map((c) => {
        'name': c['name'],
        'role': c['role'],
        'customRole': c['customRole'],
      }).toList(),
      'visibility': _visibility,
      'invitePasscode': _invitePasscode,
      'shareUrl': _shareUrl,
    };

    final success = await taskProvider.createTask(taskData);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Task "${_titleController.text.trim()}" successfully scheduled!'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackProvider = context.watch<TrackProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Task Name / Title
              const Text('Task Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Implement WebRTC Calling Signatures',
                  prefixIcon: Icon(Icons.check_box_outline_blank_rounded),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Priority Selection Chips
              const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip('low', 'Low', AppColors.emerald),
                  const SizedBox(width: 8),
                  _buildPriorityChip('medium', 'Medium', AppColors.accentCyan),
                  const SizedBox(width: 8),
                  _buildPriorityChip('high', 'High', AppColors.accentGold),
                  const SizedBox(width: 8),
                  _buildPriorityChip('urgent', 'Urgent', AppColors.rose),
                ],
              ),

              const SizedBox(height: 18),

              // 3. Description & Details
              const Text('Description & Detailed Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add comprehensive notes, links, criteria, or collaborator instructions...',
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 16),

              // 4. Scheduled Date & Time Controls
              const Text('Scheduled Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.darkBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _scheduledDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _scheduledDate = picked;
                            if (_repeatStartDate == null) _repeatStartDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryLight),
                      label: Text(
                        DateFormat('EEE, MMM d, y').format(_scheduledDate),
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.darkBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _scheduledTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _scheduledTime = picked);
                      },
                      icon: const Icon(Icons.access_time, size: 16, color: AppColors.accentCyan),
                      label: Text(
                        _scheduledTime != null ? _scheduledTime!.format(context) : 'Start Time',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // All Day & All Day Until Complete
              SwitchListTile(
                title: const Text('All-Day Event', style: TextStyle(fontSize: 14)),
                value: _isAllDay,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isAllDay = val),
              ),
              SwitchListTile(
                title: const Text('All Day Until Complete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Task persists on your daily dashboard each morning until marked complete.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                value: _isAllDayUntilComplete,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isAllDayUntilComplete = val),
              ),

              const SizedBox(height: 12),

              // Hard Deadline Date & Time
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 18, color: AppColors.rose),
                        const SizedBox(width: 8),
                        const Text('Hard Deadline (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        if (_deadlineDate != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _deadlineDate = null;
                              _deadlineTime = null;
                            }),
                            child: const Text('Clear', style: TextStyle(color: AppColors.rose, fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.darkBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _deadlineDate ?? _scheduledDate,
                                firstDate: _scheduledDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _deadlineDate = picked);
                            },
                            icon: const Icon(Icons.event, size: 14),
                            label: Text(
                              _deadlineDate != null ? DateFormat('MMM d, y').format(_deadlineDate!) : 'Pick Deadline Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.darkBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _deadlineDate == null ? null : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _deadlineTime ?? const TimeOfDay(hour: 23, minute: 59),
                              );
                              if (picked != null) setState(() => _deadlineTime = picked);
                            },
                            icon: const Icon(Icons.timer, size: 14),
                            label: Text(
                              _deadlineTime != null ? _deadlineTime!.format(context) : 'Deadline Time',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 16),

              // 5. Recurrence Configuration
              const Text('Recurrence Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _repeatType,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.repeat_rounded)),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('No Repetition (One-time Task)')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily Repetition')),
                  DropdownMenuItem(value: 'weekdays', child: Text('Selected Weekdays')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly Repetition (Same day each week)')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly Repetition (Same day each month)')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Interval (Every N days)')),
                  DropdownMenuItem(value: 'repeat_until_completed', child: Text('Repeat Until Completed')),
                ],
                onChanged: (val) => setState(() => _repeatType = val!),
              ),

              if (_repeatType == 'weekdays') ...[
                const SizedBox(height: 12),
                const Text('Select Active Weekdays:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWeekdayChip(1, 'Mon'),
                    _buildWeekdayChip(2, 'Tue'),
                    _buildWeekdayChip(3, 'Wed'),
                    _buildWeekdayChip(4, 'Thu'),
                    _buildWeekdayChip(5, 'Fri'),
                    _buildWeekdayChip(6, 'Sat'),
                    _buildWeekdayChip(7, 'Sun'),
                  ],
                ),
              ],

              if (_repeatType == 'custom') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Repeat every: ', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: _customIntervalController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('days', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],

              if (_repeatType != 'none') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Repeat Start Date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _repeatStartDate ?? _scheduledDate,
                                firstDate: _scheduledDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _repeatStartDate = picked);
                            },
                            child: Text(
                              _repeatStartDate != null ? DateFormat('MMM d, y').format(_repeatStartDate!) : 'Start Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Repeat Until (Optional)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _repeatEndDate ?? _scheduledDate.add(const Duration(days: 30)),
                                firstDate: _scheduledDate,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _repeatEndDate = picked);
                            },
                            child: Text(
                              _repeatEndDate != null ? DateFormat('MMM d, y').format(_repeatEndDate!) : 'Forever / No End',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 16),

              // 6. Track Assignment (Standalone vs Track Selector)
              const Text('Track Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedTrackId,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.route_rounded)),
                hint: const Text('Standalone Task (Not linked to any Track)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Standalone Task (No Track)')),
                  ...trackProvider.userTracks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))),
                ],
                onChanged: (val) => setState(() => _selectedTrackId = val),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 16),

              // 7. Collaborators & Roles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Collaborators & Roles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add Member'),
                    onPressed: _showAddCollaboratorDialog,
                  ),
                ],
              ),
              if (_collaborators.isEmpty)
                const Text('No additional collaborators assigned. You are the sole Owner.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _collaborators.map((c) => Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(c['name']!.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                    label: Text('${c['name']} (${c['role']!.toUpperCase()})', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _collaborators.remove(c)),
                  )).toList(),
                ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 16),

              // 8. Attachments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attachments & Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: const Text('Add File'),
                    onPressed: _addAttachmentMock,
                  ),
                ],
              ),
              if (_attachments.isEmpty)
                const Text('No files attached.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                ..._attachments.map((att) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.description, size: 18, color: AppColors.accentCyan),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${att['name']} (${att['size']})', style: const TextStyle(fontSize: 13))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.rose),
                        onPressed: () => setState(() => _attachments.remove(att)),
                      ),
                    ],
                  ),
                )),

              const SizedBox(height: 20),
              const Divider(color: AppColors.darkBorder),
              const SizedBox(height: 16),

              // 9. Visibility & Passcode Invitation
              const Text('Visibility & Sharing Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Private Task'),
                    selected: _visibility == 'private',
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setState(() => _visibility = 'private'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Public Task'),
                    selected: _visibility == 'public',
                    selectedColor: AppColors.accentCyan,
                    onSelected: (_) => setState(() => _visibility = 'public'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Secure Passcode Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vpn_key_outlined, size: 16, color: AppColors.accentGold),
                        const SizedBox(width: 6),
                        const Text('Private Access Passcode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                        const Spacer(),
                        Text(_invitePasscode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.black, letterSpacing: 1.5, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Secure Link: $_shareUrl', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 10. Save and Cancel Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.darkBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _handleSave,
                      child: _isSubmitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String key, String label, Color color) {
    final isSelected = _priority == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppColors.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : AppColors.darkBorder, width: isSelected ? 1.5 : 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayChip(int dayIndex, String label) {
    final isSelected = _selectedWeekdays.contains(dayIndex);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedWeekdays.length > 1) _selectedWeekdays.remove(dayIndex);
          } else {
            _selectedWeekdays.add(dayIndex);
          }
        });
      },
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.darkBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textMuted),
        ),
      ),
    );
  }

  void _showAddCollaboratorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Task Collaborator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _collaboratorNameController,
                decoration: const InputDecoration(hintText: 'Collaborator Name or Email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('Member (Default)')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  DropdownMenuItem(value: 'owner', child: Text('Co-Owner')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Role Title')),
                ],
                onChanged: (val) => setDialogState(() => _selectedRole = val!),
              ),
              if (_selectedRole == 'custom') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customRoleController,
                  decoration: const InputDecoration(hintText: 'e.g. Lead Reviewer'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = _collaboratorNameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _collaborators.add({
                      'name': name,
                      'role': _selectedRole,
                      'customRole': _selectedRole == 'custom' ? _customRoleController.text.trim() : '',
                    });
                  });
                  _collaboratorNameController.clear();
                  _customRoleController.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addAttachmentMock() {
    setState(() {
      _attachments.add({
        'name': 'Sprint_Specs_v2.pdf',
        'url': 'https://telos.app/files/specs.pdf',
        'size': '1.8 MB',
        'fileType': 'application/pdf',
      });
    });
  }
}
