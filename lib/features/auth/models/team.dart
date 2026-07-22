import '../../../core/models/base_model.dart';

class Team extends BaseModel {
  final String name;

  Team({
    required super.id,
    required super.createdAt,
    required this.name,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      name: json['name'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
    );
  }
}
