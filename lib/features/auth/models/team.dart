import '../../../core/models/base_model.dart';

class Team extends BaseModel {
  final String name;
  final String? password;

  Team({
    required super.id,
    required super.createdAt,
    required this.name,
    this.password,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      name: json['name'] as String,
      password: json['password'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? password,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      password: password ?? this.password,
    );
  }

  /// 获取团队专属 6 位大写邀请码
  /// 注意：邀请码需要移除 UUID 中的连字符后取前 6 位
  String get inviteCode {
    final cleanId = id.replaceAll('-', '');
    if (cleanId.length >= 6) {
      return cleanId.substring(0, 6).toUpperCase();
    }
    return cleanId.toUpperCase();
  }
}
