import 'package:flutter/material.dart';
import '../network/api_client.dart';

class RewardsProvider extends ChangeNotifier {
  int _balance = 160;
  int _pointsThisWeek = 40;
  int _pointsThisMonth = 120;
  int _streakDays = 5;
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = false;

  int get balance => _balance;
  int get pointsThisWeek => _pointsThisWeek;
  int get pointsThisMonth => _pointsThisMonth;
  int get streakDays => _streakDays;
  List<Map<String, dynamic>> get achievements => _achievements;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  bool get isLoading => _isLoading;

  Future<void> fetchRewards() async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.get('/points/chest');
    if (res['success'] == true) {
      _balance = res['currentBalance'] ?? 160;
      _pointsThisWeek = res['pointsThisWeek'] ?? 40;
      _pointsThisMonth = res['pointsThisMonth'] ?? 120;
      _streakDays = res['streakDays'] ?? 5;
      _achievements = List<Map<String, dynamic>>.from(res['achievements'] ?? []);
      _recentActivity = List<Map<String, dynamic>>.from(res['recentActivity'] ?? []);
    } else {
      _achievements = [
        {'id': '1', 'title': 'First Step', 'description': 'Created your first Track', 'unlocked': true},
        {'id': '2', 'title': 'Task Slayer', 'description': 'Completed 10 eligible tasks', 'unlocked': true},
        {'id': '3', 'title': 'Momentum Master', 'description': 'Maintained a 5-day streak', 'unlocked': true},
        {'id': '4', 'title': 'Grand Strategist', 'description': 'Reached 500 total points', 'unlocked': false},
      ];
      _recentActivity = [
        {'description': 'Completed task: Review Architecture', 'points': 10, 'createdAt': DateTime.now().toIso8601String()},
        {'description': 'Milestone bonus: Phase 1 Completed', 'points': 25, 'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
        {'description': 'Daily consistency bonus', 'points': 5, 'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      ];
    }

    _isLoading = false;
    notifyListeners();
  }
}
