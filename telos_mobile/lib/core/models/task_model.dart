class TaskCollaborator {
  final String userId;
  final String name;
  final String avatarUrl;
  final String role;
  final bool completed;

  TaskCollaborator({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.role,
    this.completed = false,
  });

  factory TaskCollaborator.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic> ? json['user'] : {};
    return TaskCollaborator(
      userId: user['_id'] ?? json['userId'] ?? '',
      name: json['name'] ?? user['displayName'] ?? json['displayName'] ?? 'Collaborator',
      avatarUrl: user['avatarUrl'] ?? '',
      role: json['role'] ?? 'member',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
      'completed': completed,
    };
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String priority; // 'low' | 'medium' | 'high' | 'urgent'
  final DateTime scheduledDate;
  final String? scheduledTime;
  final bool isAllDay;
  final bool isAllDayUntilComplete;
  final DateTime? deadline;
  final String status; // 'pending' | 'in_progress' | 'completed'
  final String repeatType;
  final String? trackId;
  final String? trackTitle;
  final String creatorName;
  final String creatorAvatar;
  final List<TaskCollaborator> collaborators;
  final String visibility;
  final String invitePasscode;
  final String shareUrl;
  final int pointsEarned;
  final bool aiGenerated;
  final String? currentOccurrenceDate;
  final List<dynamic> activityHistory;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'medium',
    required this.scheduledDate,
    this.scheduledTime,
    this.isAllDay = false,
    this.isAllDayUntilComplete = false,
    this.deadline,
    required this.status,
    this.repeatType = 'none',
    this.trackId,
    this.trackTitle,
    this.creatorName = 'You',
    this.creatorAvatar = '',
    this.collaborators = const [],
    this.visibility = 'private',
    this.invitePasscode = '',
    this.shareUrl = '',
    this.pointsEarned = 0,
    this.aiGenerated = false,
    this.currentOccurrenceDate,
    this.activityHistory = const [],
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final track = json['trackId'] is Map<String, dynamic> ? json['trackId'] : null;
    final creator = json['creator'] is Map<String, dynamic> ? json['creator'] : null;

    final rawCollaborators = json['collaborators'] as List? ?? [];
    final collaboratorsList = rawCollaborators
        .map((c) => TaskCollaborator.fromJson(c as Map<String, dynamic>))
        .toList();

    return TaskModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Task',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      scheduledTime: json['scheduledTime'],
      isAllDay: json['isAllDay'] ?? false,
      isAllDayUntilComplete: json['isAllDayUntilComplete'] ?? false,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] ?? 'pending',
      repeatType: json['repeatConfig'] != null
          ? (json['repeatConfig']['type'] ?? 'none')
          : 'none',
      trackId: track != null ? track['_id'] : (json['trackId'] is String ? json['trackId'] : null),
      trackTitle: track != null ? track['title'] : null,
      creatorName: creator != null ? (creator['displayName'] ?? 'Creator') : 'You',
      creatorAvatar: creator != null ? (creator['avatarUrl'] ?? '') : '',
      collaborators: collaboratorsList,
      visibility: json['visibility'] ?? 'private',
      invitePasscode: json['invitePasscode'] ?? '',
      shareUrl: json['shareUrl'] ?? '',
      pointsEarned: json['pointsEarned'] ?? 0,
      aiGenerated: json['aiGenerated'] ?? false,
      currentOccurrenceDate: json['currentOccurrenceDate'],
      activityHistory: json['activityHistory'] as List? ?? [],
    );
  }

  TaskModel copyWith({
    String? status,
    int? pointsEarned,
    String? currentOccurrenceDate,
  }) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      priority: priority,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      isAllDay: isAllDay,
      isAllDayUntilComplete: isAllDayUntilComplete,
      deadline: deadline,
      status: status ?? this.status,
      repeatType: repeatType,
      trackId: trackId,
      trackTitle: trackTitle,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      collaborators: collaborators,
      visibility: visibility,
      invitePasscode: invitePasscode,
      shareUrl: shareUrl,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      aiGenerated: aiGenerated,
      currentOccurrenceDate: currentOccurrenceDate ?? this.currentOccurrenceDate,
      activityHistory: activityHistory,
    );
  }
}
