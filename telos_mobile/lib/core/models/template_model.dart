class TemplateModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int durationWeeks;
  final int tasksCount;
  final int milestonesCount;

  TemplateModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationWeeks,
    required this.tasksCount,
    required this.milestonesCount,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    final tasks = json['tasksTemplate'] as List? ?? [];
    final milestones = json['milestonesTemplate'] as List? ?? [];
    return TemplateModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'productivity',
      durationWeeks: json['durationWeeks'] ?? 4,
      tasksCount: tasks.length,
      milestonesCount: milestones.length,
    );
  }
}

class ConversationModel {
  final String id;
  final String type; // 'individual' | 'group' | 'track'
  final String name;
  final String avatarUrl;
  final String lastMessageText;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<dynamic> members;

  ConversationModel({
    required this.id,
    required this.type,
    required this.name,
    required this.avatarUrl,
    required this.lastMessageText,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.members = const [],
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'] as Map<String, dynamic>? ?? {};
    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'individual',
      name: json['name'] ?? 'Chat',
      avatarUrl: json['avatarUrl'] ?? '',
      lastMessageText: lastMsg['text'] ?? 'No messages yet',
      lastMessageTime: lastMsg['createdAt'] != null
          ? DateTime.parse(lastMsg['createdAt'])
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now()),
      unreadCount: json['unreadCount'] ?? 0,
      members: json['members'] as List? ?? [],
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final String? voiceUrl;
  final Map<String, dynamic>? poll;
  final List<dynamic> reactions;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.voiceUrl,
    this.poll,
    this.reactions = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String myUserId) {
    final sender = json['sender'] is Map<String, dynamic> ? json['sender'] : {};
    final sId = sender['_id'] ?? json['senderId'] ?? '';
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: sId,
      senderName: sender['displayName'] ?? json['senderName'] ?? 'Member',
      senderAvatar: sender['avatarUrl'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isMe: sId == myUserId,
      voiceUrl: json['voiceUrl'],
      poll: json['poll'] as Map<String, dynamic>?,
      reactions: json['reactions'] as List? ?? [],
    );
  }
}

class PostModel {
  final String id;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final String text;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.text,
    this.mediaUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final author = json['author'] is Map<String, dynamic> ? json['author'] : {};
    final likes = json['likes'] as List? ?? [];
    final comments = json['comments'] as List? ?? [];

    return PostModel(
      id: json['_id'] ?? json['id'] ?? '',
      authorName: author['displayName'] ?? 'User',
      authorUsername: author['username'] ?? 'user',
      authorAvatar: author['avatarUrl'] ?? '',
      text: json['text'] ?? '',
      mediaUrls: (json['mediaUrls'] as List? ?? []).map((e) => e.toString()).toList(),
      likesCount: likes.length,
      commentsCount: comments.length,
      isLikedByMe: likes.any((id) => id.toString() == currentUserId),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
