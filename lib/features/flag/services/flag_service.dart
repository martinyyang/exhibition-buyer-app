import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flag.dart';
import '../../formula/services/formula_calculator.dart';
import '../../../core/config/network_config.dart';

/// 旗子编辑冲突异常
class FlagConflictException implements Exception {
  final String message;
  final Flag currentFlag;

  FlagConflictException(this.message, this.currentFlag);

  @override
  String toString() => message;
}

class FlagService {
  final SupabaseClient _supabase;

  FlagService(this._supabase);

  /// 创建新旗子标注（自动分配编号）
  Future<Flag> createFlag({
    required String photoId,
    required double positionX,
    required double positionY,
    required String createdBy,
  }) async {
    // 获取下一个可用编号
    final nextNumber = await getNextFlagNumber(photoId);

    final flagData = {
      'photo_id': photoId,
      'number': nextNumber,
      'position_x': positionX,
      'position_y': positionY,
      'created_by': createdBy,
    };

    final inserted = await _supabase
        .from('flags')
        .insert(flagData)
        .select()
        .single()
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('创建旗子超时'),
        );

    return Flag.fromJson(inserted);
  }

  /// 获取照片的所有旗子（按编号升序排列）
  Future<List<Flag>> getFlags(String photoId) async {
    final result = await _supabase
        .from('flags')
        .select()
        .eq('photo_id', photoId)
        .order('number', ascending: true)
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('获取旗子列表超时'),
        );

    return result.map((json) => Flag.fromJson(json)).toList();
  }

  /// 获取单个旗子详情
  Future<Flag?> getFlag(String flagId) async {
    try {
      final result =
          await _supabase.from('flags').select().eq('id', flagId).single();

      return Flag.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  /// 获取下一个可用的旗子编号
  Future<int> getNextFlagNumber(String photoId) async {
    final result = await _supabase
        .from('flags')
        .select('number')
        .eq('photo_id', photoId)
        .order('number', ascending: false)
        .limit(1);

    if (result.isEmpty) {
      return 1;
    }

    final maxNumber = result.first['number'] as int;
    return maxNumber + 1;
  }

  /// 买手更新报价（自动清除警告标记并计算换算价格，带冲突检测）
  Future<Flag> updateBuyerPrice({
    required String flagId,
    required double priceRmb,
    DateTime? expectedUpdatedAt,
    String? formula,
    String? teamId,
  }) async {
    // 如果提供了 expectedUpdatedAt，先检查冲突
    if (expectedUpdatedAt != null) {
      final currentFlag = await getFlag(flagId);
      if (currentFlag == null) {
        throw Exception('旗子不存在');
      }

      if (currentFlag.updatedAt.difference(expectedUpdatedAt).abs() >
          const Duration(seconds: 1)) {
        throw FlagConflictException(
          '此旗子已被他人修改，请刷新后重试',
          currentFlag,
        );
      }
    }

    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'price_rmb': priceRmb,
      'buyer_price_updated_at': now.toIso8601String(),
    };

    // 如果提供了公式，计算换算价格
    if (formula != null) {
      try {
        final converted = FormulaCalculator.calculate(formula, priceRmb);
        updateData['price_converted'] = converted;
      } catch (e) {
        // 公式错误时不更新换算价格
      }
    }

    final result = await _supabase
        .from('flags')
        .update(updateData)
        .eq('id', flagId)
        .select()
        .single();

    return Flag.fromJson(result);
  }

  /// 远程团队设置目标价（触发警告标记，带冲突检测）
  Future<Flag> setTargetPrice({
    required String flagId,
    required double targetPrice,
    DateTime? expectedUpdatedAt,
  }) async {
    // 如果提供了 expectedUpdatedAt，先检查冲突
    if (expectedUpdatedAt != null) {
      final currentFlag = await getFlag(flagId);
      if (currentFlag == null) {
        throw Exception('旗子不存在');
      }

      if (currentFlag.updatedAt.difference(expectedUpdatedAt).abs() >
          const Duration(seconds: 1)) {
        throw FlagConflictException(
          '此旗子已被他人修改，请刷新后重试',
          currentFlag,
        );
      }
    }

    final now = DateTime.now();
    final updateData = {
      'target_price': targetPrice,
      'target_price_updated_at': now.toIso8601String(),
    };

    final result = await _supabase
        .from('flags')
        .update(updateData)
        .eq('id', flagId)
        .select()
        .single();

    return Flag.fromJson(result);
  }

  /// 更新旗子信息（通用方法，带冲突检测）
  Future<Flag> updateFlag({
    required String flagId,
    DateTime? expectedUpdatedAt,
    double? priceRmb,
    double? priceConverted,
    double? targetPrice,
    double? positionX,
    double? positionY,
    bool? needsAttention,
    String? purchaseStatus,
  }) async {
    // 如果提供了 expectedUpdatedAt，先检查冲突
    if (expectedUpdatedAt != null) {
      final currentFlag = await getFlag(flagId);
      if (currentFlag == null) {
        throw Exception('旗子不存在');
      }

      // 比较时间戳，允许 1 秒误差（避免精度问题）
      if (currentFlag.updatedAt.difference(expectedUpdatedAt).abs() >
          const Duration(seconds: 1)) {
        throw FlagConflictException(
          '此旗子已被他人修改，请刷新后重试',
          currentFlag,
        );
      }
    }

    final updateData = <String, dynamic>{};

    if (priceRmb != null) updateData['price_rmb'] = priceRmb;
    if (priceConverted != null) updateData['price_converted'] = priceConverted;
    if (targetPrice != null) updateData['target_price'] = targetPrice;
    if (positionX != null) updateData['position_x'] = positionX;
    if (positionY != null) updateData['position_y'] = positionY;
    if (needsAttention != null) updateData['needs_attention'] = needsAttention;
    if (purchaseStatus != null) updateData['purchase_status'] = purchaseStatus;

    if (updateData.isEmpty) {
      throw ArgumentError('At least one update field is required');
    }

    final result = await _supabase
        .from('flags')
        .update(updateData)
        .eq('id', flagId)
        .select()
        .single()
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('更新旗子超时'),
        );

    return Flag.fromJson(result);
  }

  /// 更新旗子位置
  Future<Flag> updateFlagPosition({
    required String flagId,
    required double positionX,
    required double positionY,
  }) async {
    final updateData = {
      'position_x': positionX,
      'position_y': positionY,
    };

    final result = await _supabase
        .from('flags')
        .update(updateData)
        .eq('id', flagId)
        .select()
        .single();

    return Flag.fromJson(result);
  }

  /// 删除旗子
  Future<void> deleteFlag(String flagId) async {
    await _supabase.from('flags').delete().eq('id', flagId);
  }

  /// 批量更新换算价格（当公式变化时）
  Future<void> recalculatePrices({
    required String photoId,
    required String formula,
  }) async {
    final flags = await getFlags(photoId);

    for (final flag in flags) {
      if (flag.priceRmb != null) {
        try {
          final converted =
              FormulaCalculator.calculate(formula, flag.priceRmb!);
          await _supabase.from('flags').update({
            'price_converted': converted,
          }).eq('id', flag.id);
        } catch (e) {
          // 跳过计算失败的旗子
        }
      }
    }
  }

  /// 监听旗子变化（实时同步）
  RealtimeChannel subscribeFlagChanges({
    required String photoId,
    required void Function(Flag flag) onInsert,
    required void Function(Flag flag) onUpdate,
    required void Function(String flagId) onDelete,
  }) {
    final channel = _supabase
        .channel('flags:$photoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'flags',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'photo_id',
            value: photoId,
          ),
          callback: (payload) {
            onInsert(Flag.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'flags',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'photo_id',
            value: photoId,
          ),
          callback: (payload) {
            onUpdate(Flag.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'flags',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'photo_id',
            value: photoId,
          ),
          callback: (payload) {
            onDelete(payload.oldRecord['id'] as String);
          },
        )
        .subscribe();

    return channel;
  }
}
