class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String username;
  final String avatarUrl;
  final String bio;
  final String profileVisibility;
  final bool isOnboarded;
  final int points;
  final int streakDays;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.profileVisibility,
    required this.isOnboarded,
    required this.points,
    required this.streakDays,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? 'Telos User',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      bio: json['bio'] ?? '',
      profileVisibility: json['profileVisibility'] ?? 'public',
      isOnboarded: json['isOnboarded'] ?? false,
      points: json['points'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'profileVisibility': profileVisibility,
      'isOnboarded': isOnboarded,
      'points': points,
      'streakDays': streakDays,
    };
  }
}
