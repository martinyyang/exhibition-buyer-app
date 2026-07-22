abstract class BaseModel {
  final String id;
  final DateTime createdAt;

  BaseModel({
    required this.id,
    required this.createdAt,
  });

  Map<String, dynamic> toJson();

  static DateTime parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
