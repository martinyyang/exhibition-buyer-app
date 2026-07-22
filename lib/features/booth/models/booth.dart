import '../../../core/models/base_model.dart';

class Booth extends BaseModel {
  final String boothNumber;
  final String eventId;
  final String teamId;
  final String createdBy;

  Booth({
    required super.id,
    required super.createdAt,
    required this.boothNumber,
    required this.eventId,
    required this.teamId,
    required this.createdBy,
  });

  factory Booth.fromJson(Map<String, dynamic> json) {
    return Booth(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      boothNumber: json['booth_number'] as String,
      eventId: json['event_id'] as String,
      teamId: json['team_id'] as String,
      createdBy: json['created_by'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booth_number': boothNumber,
      'event_id': eventId,
      'team_id': teamId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Booth copyWith({
    String? id,
    String? boothNumber,
    String? eventId,
    String? teamId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Booth(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      boothNumber: boothNumber ?? this.boothNumber,
      eventId: eventId ?? this.eventId,
      teamId: teamId ?? this.teamId,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
