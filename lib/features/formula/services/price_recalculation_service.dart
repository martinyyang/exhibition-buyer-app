import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/formula_calculator.dart';

/// 价格重算服务，用于公式变更后批量更新旗子的换算价格
class PriceRecalculationService {
  final SupabaseClient _supabase;

  PriceRecalculationService(this._supabase);

  /// 重算团队所有旗子的换算价格（公式变更后触发）
  Future<void> recalculateTeamPrices({
    required String teamId,
    required String formula,
  }) async {
    if (formula.isEmpty) {
      // 如果公式为空，清除所有换算价格
      await _clearConvertedPrices(teamId);
      return;
    }

    // 通过关联查询获取团队所有有价格的旗子
    // flags -> photos -> booths -> events (team_id)
    final flags = await _supabase
        .from('flags')
        .select(
            'id, price_rmb, photo_id, photos!inner(booth_id, booths!inner(event_id, events!inner(team_id)))')
        .not('price_rmb', 'is', null)
        .eq('photos.booths.events.team_id', teamId);

    if (flags.isEmpty) return;

    // 批量计算并更新换算价格
    final updates = <Map<String, dynamic>>[];
    for (final flag in flags) {
      final flagId = flag['id'] as String;
      final priceRmb = (flag['price_rmb'] as num).toDouble();

      try {
        final converted = FormulaCalculator.calculate(formula, priceRmb);
        updates.add({
          'id': flagId,
          'price_converted': converted,
        });
      } catch (e) {
        // 计算失败时保持原换算价格不变
        continue;
      }
    }

    // 批量更新（使用 upsert 避免冲突）
    if (updates.isNotEmpty) {
      await _supabase.from('flags').upsert(updates);
    }
  }

  /// 清除团队所有旗子的换算价格
  Future<void> _clearConvertedPrices(String teamId) async {
    // 通过关联查询清除团队旗子的换算价格
    final flags = await _supabase
        .from('flags')
        .select(
            'id, photos!inner(booth_id, booths!inner(event_id, events!inner(team_id)))')
        .eq('photos.booths.events.team_id', teamId);

    if (flags.isEmpty) return;

    final flagIds = flags.map((f) => f['id'] as String).toList();
    await _supabase
        .from('flags')
        .update({'price_converted': null}).inFilter('id', flagIds);
  }

  /// 重算单张照片的旗子价格
  Future<void> recalculatePhotoPrices({
    required String photoId,
    required String formula,
  }) async {
    if (formula.isEmpty) {
      // 如果公式为空，清除换算价格
      await _supabase
          .from('flags')
          .update({'price_converted': null}).eq('photo_id', photoId);
      return;
    }

    // 获取照片所有有价格的旗子
    final flags = await _supabase
        .from('flags')
        .select('id, price_rmb')
        .not('price_rmb', 'is', null)
        .eq('photo_id', photoId);

    if (flags.isEmpty) return;

    // 批量计算并更新
    final updates = <Map<String, dynamic>>[];
    for (final flag in flags) {
      final flagId = flag['id'] as String;
      final priceRmb = flag['price_rmb'] as double;

      try {
        final converted = FormulaCalculator.calculate(formula, priceRmb);
        updates.add({
          'id': flagId,
          'price_converted': converted,
        });
      } catch (e) {
        continue;
      }
    }

    if (updates.isNotEmpty) {
      await _supabase.from('flags').upsert(updates);
    }
  }
}
