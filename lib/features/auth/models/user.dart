import '../../../core/models/base_model.dart';

class User extends BaseModel {
  final String email;
  final String role; // 'buyer' | 'remote'
  final String? teamId;
  final String? dailyColor;
  final DateTime? colorAssignedDate;
  final DateTime? lastSeen;

  User({
    required super.id,
    required super.createdAt,
    required this.email,
    required this.role,
    this.teamId,
    this.dailyColor,
    this.colorAssignedDate,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      email: json['email'] as String,
      role: json['role'] as String,
      teamId: json['team_id'] as String?,
      dailyColor: json['daily_color'] as String?,
      colorAssignedDate: json['color_assigned_date'] != null
          ? DateTime.parse(json['color_assigned_date'] as String)
          : null,
      lastSeen: json['last_seen'] != null
          ? BaseModel.parseTimestamp(json['last_seen'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'team_id': teamId,
      'daily_color': dailyColor,
      'color_assigned_date': colorAssignedDate?.toIso8601String().split('T')[0],
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? role,
    String? teamId,
    String? dailyColor,
    DateTime? colorAssignedDate,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      dailyColor: dailyColor ?? this.dailyColor,
      colorAssignedDate: colorAssignedDate ?? this.colorAssignedDate,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  bool get isBuyer => role == 'buyer';
  bool get isRemote => role == 'remote';

  /// 判断用户是否在线（最近5分钟内活跃）
  bool get isOnline {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inMinutes < 5;
  }
}
