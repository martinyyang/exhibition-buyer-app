import '../../../core/models/base_model.dart';

class Photo extends BaseModel {
  final String boothId;
  final String url;
  final String? supplierName;
  final String? supplierLogoUrl;
  final String uploadedBy;

  Photo({
    required super.id,
    required super.createdAt,
    required this.boothId,
    required this.url,
    this.supplierName,
    this.supplierLogoUrl,
    required this.uploadedBy,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      boothId: json['booth_id'] as String,
      url: json['url'] as String,
      supplierName: json['supplier_name'] as String?,
      supplierLogoUrl: json['supplier_logo_url'] as String?,
      uploadedBy: json['uploaded_by'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booth_id': boothId,
      'url': url,
      'supplier_name': supplierName,
      'supplier_logo_url': supplierLogoUrl,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Photo copyWith({
    String? id,
    String? boothId,
    String? url,
    String? supplierName,
    String? supplierLogoUrl,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      boothId: boothId ?? this.boothId,
      url: url ?? this.url,
      supplierName: supplierName ?? this.supplierName,
      supplierLogoUrl: supplierLogoUrl ?? this.supplierLogoUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }
}
