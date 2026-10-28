import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../network/api_client.dart';

class TaskProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchTasksForDate(date);
  }

  Future<void> fetchTasksForDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await ApiClient.get('/tasks?date=$dateStr');

    if (res['success'] == true && res['tasks'] != null) {
      final rawList = res['tasks'] as List;
      _tasks = rawList.map((t) => TaskModel.fromJson(t)).toList();
    } else {
      // Offline/seed resilient initial state
      if (_tasks.isEmpty) {
        _tasks = [
          TaskModel(
            id: 'task_1',
            title: 'Review System Architecture & Track Milestones',
            description: 'Evaluate cross-platform synchronization and check off Phase 1 requirements.',
            scheduledDate: date,
            scheduledTime: '09:30 AM',
            status: 'pending',
            trackTitle: 'Full-Stack Software Launch Roadmap',
            collaborators: [
              TaskCollaborator(userId: 'collab_1', name: 'Alex Rivera', avatarUrl: '', role: 'member'),
            ],
            visibility: 'private',
            pointsEarned: 0,
          ),
          TaskModel(
            id: 'task_2',
            title: 'Daily Deep Focus Sprint (45 mins)',
            description: 'Uninterrupted deep work on core TELOS features without distractions.',
            scheduledDate: date,
            scheduledTime: '11:00 AM',
            isAllDayUntilComplete: true,
            status: 'pending',
            repeatType: 'daily',
            pointsEarned: 0,
          ),
          TaskModel(
            id: 'task_3',
            title: 'Complete Weekly Milestones Check-in',
            description: 'Collaborative group alignment with Track team members.',
            scheduledDate: date,
            scheduledTime: '04:00 PM',
            status: 'completed',
            trackTitle: 'Exam Mastery & Academic Sprint',
            pointsEarned: 10,
          ),
        ];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    // Optimistic UI toggle
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    final newPoints = newStatus == 'completed' && task.pointsEarned == 0 ? 10 : task.pointsEarned;

    _tasks[index] = task.copyWith(
      status: newStatus,
      pointsEarned: newPoints,
    );
    notifyListeners();

    try {
      await ApiClient.patch('/tasks/${task.id}/toggle');
    } catch (e) {
      print('Toggle sync error: $e');
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.post('/tasks', data);

    if (res['success'] == true && res['task'] != null) {
      _tasks.insert(0, TaskModel.fromJson(res['task']));
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Local resilient insert if server offline
    final newTask = TaskModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: data['title'] ?? 'New Task',
      description: data['description'] ?? '',
      scheduledDate: DateTime.parse(data['scheduledDate']),
      scheduledTime: data['scheduledTime'],
      isAllDay: data['isAllDay'] ?? false,
      isAllDayUntilComplete: data['isAllDayUntilComplete'] ?? false,
      status: 'pending',
      repeatType: data['repeatConfig']?['type'] ?? 'none',
      visibility: data['visibility'] ?? 'private',
    );
    _tasks.insert(0, newTask);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    try {
      await ApiClient.delete('/tasks/$taskId');
    } catch (e) {
      print('Delete task error: $e');
    }
  }
}
