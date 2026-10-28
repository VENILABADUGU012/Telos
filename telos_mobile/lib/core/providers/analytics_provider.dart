import 'package:flutter/material.dart';
import '../network/api_client.dart';

class AnalyticsProvider extends ChangeNotifier {
  String _selectedPeriod = 'weekly'; // 'weekly' | 'monthly' | 'yearly'
  int _totalScheduled = 12;
  int _completedTasks = 8;
  int _inProgressTasks = 2;
  int _pendingTasks = 2;
  int _completionPercentage = 67;
  int _overallTrackProgress = 54;
  int _pointsEarnedPeriod = 80;
  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _tracksComparison = [];
  bool _isLoading = false;

  String get selectedPeriod => _selectedPeriod;
  int get totalScheduled => _totalScheduled;
  int get completedTasks => _completedTasks;
  int get inProgressTasks => _inProgressTasks;
  int get pendingTasks => _pendingTasks;
  int get completionPercentage => _completionPercentage;
  int get overallTrackProgress => _overallTrackProgress;
  int get pointsEarnedPeriod => _pointsEarnedPeriod;
  List<Map<String, dynamic>> get trends => _trends;
  List<Map<String, dynamic>> get tracksComparison => _tracksComparison;
  bool get isLoading => _isLoading;

  void setPeriod(String period) {
    _selectedPeriod = period;
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.get('/analytics?period=$_selectedPeriod');
    if (res['success'] == true && res['metrics'] != null) {
      final metrics = res['metrics'];
      _totalScheduled = metrics['totalScheduled'] ?? 0;
      _completedTasks = metrics['completedTasks'] ?? 0;
      _inProgressTasks = metrics['inProgressTasks'] ?? 0;
      _pendingTasks = metrics['pendingTasks'] ?? 0;
      _completionPercentage = metrics['completionPercentage'] ?? 0;
      _overallTrackProgress = metrics['overallTrackProgress'] ?? 0;
      _pointsEarnedPeriod = metrics['pointsEarnedPeriod'] ?? 0;
      _trends = List<Map<String, dynamic>>.from(res['trends'] ?? []);
      _tracksComparison = List<Map<String, dynamic>>.from(res['tracksComparison'] ?? []);
    } else {
      // Default fallback analytics data
      if (_selectedPeriod == 'weekly') {
        _totalScheduled = 14;
        _completedTasks = 10;
        _completionPercentage = 71;
        _pointsEarnedPeriod = 100;
        _trends = [
          {'label': 'Mon', 'completedCount': 2},
          {'label': 'Tue', 'completedCount': 1},
          {'label': 'Wed', 'completedCount': 3},
          {'label': 'Thu', 'completedCount': 2},
          {'label': 'Fri', 'completedCount': 1},
          {'label': 'Sat', 'completedCount': 1},
          {'label': 'Sun', 'completedCount': 0},
        ];
      } else if (_selectedPeriod == 'monthly') {
        _totalScheduled = 48;
        _completedTasks = 36;
        _completionPercentage = 75;
        _pointsEarnedPeriod = 360;
        _trends = [
          {'label': 'W1', 'completedCount': 8},
          {'label': 'W2', 'completedCount': 10},
          {'label': 'W3', 'completedCount': 9},
          {'label': 'W4', 'completedCount': 9},
        ];
      } else {
        _totalScheduled = 450;
        _completedTasks = 380;
        _completionPercentage = 84;
        _pointsEarnedPeriod = 3800;
        _trends = [
          {'label': 'Q1', 'completedCount': 90},
          {'label': 'Q2', 'completedCount': 105},
          {'label': 'Q3', 'completedCount': 95},
          {'label': 'Q4', 'completedCount': 90},
        ];
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
