import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flag.dart';
import '../../formula/services/formula_calculator.dart';

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
        .single();

    return Flag.fromJson(inserted);
  }

  /// 获取照片的所有旗子（按编号升序排列）
  Future<List<Flag>> getFlags(String photoId) async {
    final result = await _supabase
        .from('flags')
        .select()
        .eq('photo_id', photoId)
        .order('number', ascending: true);

    return result.map((json) => Flag.fromJson(json)).toList();
  }

  /// 获取单个旗子详情
  Future<Flag?> getFlag(String flagId) async {
    try {
      final result = await _supabase
          .from('flags')
          .select()
          .eq('id', flagId)
          .single();

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

  /// 买手更新报价（自动清除警告标记并计算换算价格）
  Future<Flag> updateBuyerPrice({
    required String flagId,
    required double priceRmb,
    String? formula,
    String? teamId,
  }) async {
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

  /// 远程团队设置目标价（触发警告标记）
  Future<Flag> setTargetPrice({
    required String flagId,
    required double targetPrice,
  }) async {
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

  /// 更新旗子信息（通用方法）
  Future<Flag> updateFlag({
    required String flagId,
    double? priceRmb,
    double? priceConverted,
    double? targetPrice,
    double? positionX,
    double? positionY,
  }) async {
    final updateData = <String, dynamic>{};

    if (priceRmb != null) updateData['price_rmb'] = priceRmb;
    if (priceConverted != null) updateData['price_converted'] = priceConverted;
    if (targetPrice != null) updateData['target_price'] = targetPrice;
    if (positionX != null) updateData['position_x'] = positionX;
    if (positionY != null) updateData['position_y'] = positionY;

    if (updateData.isEmpty) {
      throw ArgumentError('至少需要提供一个更新字段');
    }

    final result = await _supabase
        .from('flags')
        .update(updateData)
        .eq('id', flagId)
        .select()
        .single();

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
          final converted = FormulaCalculator.calculate(formula, flag.priceRmb!);
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
