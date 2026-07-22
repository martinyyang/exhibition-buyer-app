import '../../../core/models/base_model.dart';

class Flag extends BaseModel {
  final String photoId;
  final int number;
  final double positionX;
  final double positionY;
  final double? priceRmb;
  final double? priceConverted;
  final double? targetPrice;
  final DateTime? targetPriceUpdatedAt;
  final DateTime? buyerPriceUpdatedAt;
  final bool needsAttention;
  final String createdBy;

  Flag({
    required super.id,
    required super.createdAt,
    required this.photoId,
    required this.number,
    required this.positionX,
    required this.positionY,
    this.priceRmb,
    this.priceConverted,
    this.targetPrice,
    this.targetPriceUpdatedAt,
    this.buyerPriceUpdatedAt,
    required this.needsAttention,
    required this.createdBy,
  });

  factory Flag.fromJson(Map<String, dynamic> json) {
    return Flag(
      id: json['id'] as String,
      createdAt: BaseModel.parseTimestamp(json['created_at']),
      photoId: json['photo_id'] as String,
      number: json['number'] as int,
      positionX: (json['position_x'] as num).toDouble(),
      positionY: (json['position_y'] as num).toDouble(),
      priceRmb: json['price_rmb'] != null
          ? (json['price_rmb'] as num).toDouble()
          : null,
      priceConverted: json['price_converted'] != null
          ? (json['price_converted'] as num).toDouble()
          : null,
      targetPrice: json['target_price'] != null
          ? (json['target_price'] as num).toDouble()
          : null,
      targetPriceUpdatedAt: json['target_price_updated_at'] != null
          ? BaseModel.parseTimestamp(json['target_price_updated_at'])
          : null,
      buyerPriceUpdatedAt: json['buyer_price_updated_at'] != null
          ? BaseModel.parseTimestamp(json['buyer_price_updated_at'])
          : null,
      needsAttention: json['needs_attention'] as bool? ?? false,
      createdBy: json['created_by'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo_id': photoId,
      'number': number,
      'position_x': positionX,
      'position_y': positionY,
      'price_rmb': priceRmb,
      'price_converted': priceConverted,
      'target_price': targetPrice,
      'target_price_updated_at': targetPriceUpdatedAt?.toIso8601String(),
      'buyer_price_updated_at': buyerPriceUpdatedAt?.toIso8601String(),
      'needs_attention': needsAttention,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Flag copyWith({
    String? id,
    String? photoId,
    int? number,
    double? positionX,
    double? positionY,
    double? priceRmb,
    double? priceConverted,
    double? targetPrice,
    DateTime? targetPriceUpdatedAt,
    DateTime? buyerPriceUpdatedAt,
    bool? needsAttention,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Flag(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      photoId: photoId ?? this.photoId,
      number: number ?? this.number,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      priceRmb: priceRmb ?? this.priceRmb,
      priceConverted: priceConverted ?? this.priceConverted,
      targetPrice: targetPrice ?? this.targetPrice,
      targetPriceUpdatedAt: targetPriceUpdatedAt ?? this.targetPriceUpdatedAt,
      buyerPriceUpdatedAt: buyerPriceUpdatedAt ?? this.buyerPriceUpdatedAt,
      needsAttention: needsAttention ?? this.needsAttention,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
