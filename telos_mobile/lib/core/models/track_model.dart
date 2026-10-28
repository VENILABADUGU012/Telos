class TrackMilestone {
  final String title;
  final DateTime targetDate;
  final bool completed;

  TrackMilestone({
    required this.title,
    required this.targetDate,
    required this.completed,
  });

  factory TrackMilestone.fromJson(Map<String, dynamic> json) {
    return TrackMilestone(
      title: json['title'] ?? '',
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : DateTime.now(),
      completed: json['completed'] ?? false,
    );
  }
}

class TrackModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String visibility; // 'public' | 'private'
  final String category;
  final int progressPercentage;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final String creatorName;
  final int collaboratorsCount;
  final List<TrackMilestone> milestones;

  TrackModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.visibility,
    this.category = 'productivity',
    this.progressPercentage = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.inProgressTasks = 0,
    this.creatorName = 'You',
    this.collaboratorsCount = 1,
    this.milestones = const [],
  });

  bool get isPublic => visibility == 'public';
  bool get isPrivate => visibility == 'private';
  bool get isCompleted => progressPercentage == 100;

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    final creator = json['creator'] is Map<String, dynamic> ? json['creator'] : null;
    final collabs = json['collaborators'] as List? ?? [];

    final rawMilestones = json['milestones'] as List? ?? [];
    final milestonesList = rawMilestones
        .map((m) => TrackMilestone.fromJson(m as Map<String, dynamic>))
        .toList();

    return TrackModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Track',
      description: json['description'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now().add(const Duration(days: 30)),
      visibility: json['visibility'] ?? 'private',
      category: json['category'] ?? 'productivity',
      progressPercentage: (progress['percentage'] ?? 0).toInt(),
      totalTasks: (progress['totalTasks'] ?? 0).toInt(),
      completedTasks: (progress['completedTasks'] ?? 0).toInt(),
      pendingTasks: (progress['pendingTasks'] ?? 0).toInt(),
      inProgressTasks: (progress['inProgressTasks'] ?? 0).toInt(),
      creatorName: creator != null ? (creator['displayName'] ?? 'Creator') : 'You',
      collaboratorsCount: collabs.length > 0 ? collabs.length : 1,
      milestones: milestonesList,
    );
  }
}
