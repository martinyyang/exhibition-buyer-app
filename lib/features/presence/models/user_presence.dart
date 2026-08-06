class UserPresence {
  final String userId;
  final String teamId;
  final String status;
  final DateTime lastSeen;
  final String? currentScreen;
  final Map<String, dynamic>? currentContext;
  final DateTime updatedAt;

  // 关联的用户信息
  final String? userName;
  final String? userEmail;

  UserPresence({
    required this.userId,
    required this.teamId,
    required this.status,
    required this.lastSeen,
    this.currentScreen,
    this.currentContext,
    required this.updatedAt,
    this.userName,
    this.userEmail,
  });

  bool get isOnline => status == 'online';

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;

    return UserPresence(
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      status: json['status'] as String,
      lastSeen: DateTime.parse(json['last_seen'] as String),
      currentScreen: json['current_screen'] as String?,
      currentContext: json['current_context'] as Map<String, dynamic>?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: users?['name'] as String?,
      userEmail: users?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'team_id': teamId,
      'status': status,
      'last_seen': lastSeen.toIso8601String(),
      'current_screen': currentScreen,
      'current_context': currentContext,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPresence copyWith({
    String? userId,
    String? teamId,
    String? status,
    DateTime? lastSeen,
    String? currentScreen,
    Map<String, dynamic>? currentContext,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      currentScreen: currentScreen ?? this.currentScreen,
      currentContext: currentContext ?? this.currentContext,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
