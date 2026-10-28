import 'package:flutter/material.dart';
import '../models/track_model.dart';
import '../models/template_model.dart';
import '../network/api_client.dart';

class TrackProvider extends ChangeNotifier {
  List<TrackModel> _userTracks = [];
  List<TrackModel> _publicTracks = [];
  List<TemplateModel> _templates = [];
  bool _isLoading = false;
  String _currentFilter = 'all';

  List<TrackModel> get userTracks => _userTracks;
  List<TrackModel> get publicTracks => _publicTracks;
  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;

  Future<void> fetchUserTracks({String filter = 'all', String sort = 'updatedAt'}) async {
    _isLoading = true;
    _currentFilter = filter;
    notifyListeners();

    final res = await ApiClient.get('/tracks?filter=$filter&sort=$sort');

    if (res['success'] == true && res['tracks'] != null) {
      final rawList = res['tracks'] as List;
      _userTracks = rawList.map((t) => TrackModel.fromJson(t)).toList();
    } else {
      if (_userTracks.isEmpty) {
        _userTracks = [
          TrackModel(
            id: 'track_seed_1',
            title: 'Full-Stack Software Launch Roadmap',
            description: '30-day production path for personal productivity application deployment.',
            startDate: DateTime.now().subtract(const Duration(days: 5)),
            endDate: DateTime.now().add(const Duration(days: 25)),
            visibility: 'public',
            category: 'project',
            progressPercentage: 42,
            totalTasks: 12,
            completedTasks: 5,
            pendingTasks: 5,
            inProgressTasks: 2,
            collaboratorsCount: 3,
            milestones: [
              TrackMilestone(title: 'Architecture & Schema Approved', targetDate: DateTime.now().subtract(const Duration(days: 2)), completed: true),
              TrackMilestone(title: 'Mobile MVP & Realtime Sync', targetDate: DateTime.now().add(const Duration(days: 10)), completed: false),
              TrackMilestone(title: 'Production Store Release', targetDate: DateTime.now().add(const Duration(days: 25)), completed: false),
            ],
          ),
          TrackModel(
            id: 'track_seed_2',
            title: 'Exam Mastery & Academic Sprint',
            description: 'Structured revision blocks, question papers, and weekly mock exams.',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().add(const Duration(days: 18)),
            visibility: 'private',
            category: 'academic',
            progressPercentage: 65,
            totalTasks: 20,
            completedTasks: 13,
            pendingTasks: 7,
            inProgressTasks: 0,
            collaboratorsCount: 1,
          ),
        ];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPublicTracks({String search = '', String category = 'all'}) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.get('/tracks/public?search=$search&category=$category');
    if (res['success'] == true && res['tracks'] != null) {
      final rawList = res['tracks'] as List;
      _publicTracks = rawList.map((t) => TrackModel.fromJson(t)).toList();
    } else {
      _publicTracks = [
        TrackModel(
          id: 'public_1',
          title: 'Open Science & Machine Learning Sprint',
          description: 'Community study group covering deep learning foundations and practical PyTorch benchmarks.',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 45)),
          visibility: 'public',
          category: 'academic',
          progressPercentage: 20,
          totalTasks: 15,
          completedTasks: 3,
          collaboratorsCount: 14,
          creatorName: 'Dr. Sophia Lin',
        ),
        TrackModel(
          id: 'public_2',
          title: 'Marathon 10K Endurance Habit',
          description: 'Progressive weekly pacing, tempo intervals, and recovery walks for aspiring runners.',
          startDate: DateTime.now().subtract(const Duration(days: 3)),
          endDate: DateTime.now().add(const Duration(days: 27)),
          visibility: 'public',
          category: 'fitness',
          progressPercentage: 35,
          totalTasks: 18,
          completedTasks: 6,
          collaboratorsCount: 8,
          creatorName: 'Marcus Cole',
        ),
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTemplates() async {
    final res = await ApiClient.get('/tracks/templates');
    if (res['success'] == true && res['templates'] != null) {
      final rawList = res['templates'] as List;
      _templates = rawList.map((t) => TemplateModel.fromJson(t)).toList();
    } else {
      _templates = [
        TemplateModel(
          id: 'tpl_1',
          title: 'Exam Mastery & Academic Sprint',
          description: '4-week study structure with high-yield focus, mock tests, and weak-area drills.',
          category: 'academic',
          durationWeeks: 4,
          tasksCount: 6,
          milestonesCount: 3,
        ),
        TemplateModel(
          id: 'tpl_2',
          title: 'Full-Stack Software Launch Roadmap',
          description: '30-day complete roadmap from database architecture to MVP and release.',
          category: 'project',
          durationWeeks: 4,
          tasksCount: 6,
          milestonesCount: 3,
        ),
        TemplateModel(
          id: 'tpl_3',
          title: '30-Day Peak Fitness & Habit Transformation',
          description: 'Daily consistency habits, split strength workouts, and conditioning.',
          category: 'fitness',
          durationWeeks: 4,
          tasksCount: 5,
          milestonesCount: 3,
        ),
      ];
    }
    notifyListeners();
  }

  Future<bool> applyTemplate(String templateId) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.post('/tracks/templates/$templateId/apply', {});
    if (res['success'] == true && res['track'] != null) {
      _userTracks.insert(0, TrackModel.fromJson(res['track']));
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> createTrack(Map<String, dynamic> trackData) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.post('/tracks', trackData);
    if (res['success'] == true && res['track'] != null) {
      _userTracks.insert(0, TrackModel.fromJson(res['track']));
      _isLoading = false;
      notifyListeners();
      return true;
    }

    final newTrack = TrackModel(
      id: 'local_track_${DateTime.now().millisecondsSinceEpoch}',
      title: trackData['title'] ?? 'New Track',
      description: trackData['description'] ?? '',
      startDate: DateTime.parse(trackData['startDate']),
      endDate: DateTime.parse(trackData['endDate']),
      visibility: trackData['visibility'] ?? 'private',
      category: trackData['category'] ?? 'productivity',
      progressPercentage: 0,
      totalTasks: (trackData['tasks'] as List?)?.length ?? 0,
    );
    _userTracks.insert(0, newTrack);

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
