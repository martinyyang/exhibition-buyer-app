import '../../../core/models/base_model.dart';

class Event extends BaseModel {
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String teamId;
  final bool isActive;

  Event({
    required super.id,
    required super.createdAt,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.teamId,
    required this.isActive,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      teamId: json['team_id'] as String,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'team_id': teamId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? teamId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      teamId: teamId ?? this.teamId,
      isActive: isActive ?? this.isActive,
    );
  }
}
