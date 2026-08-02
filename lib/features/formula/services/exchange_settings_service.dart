import 'package:supabase_flutter/supabase_flutter.dart';
import 'formula_calculator.dart';
import 'formula_history_service.dart';

class ExchangeSettingsService {
  final SupabaseClient _supabase;
  final FormulaHistoryService _historyService;

  ExchangeSettingsService(this._supabase, this._historyService);

  /// 获取当前活跃的汇率公式
  Future<String?> getCurrentFormula(String teamId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    print('[getCurrentFormula] Querying for teamId=$teamId, date=$todayStr');

    final result = await _supabase
        .from('exchange_settings')
        .select()
        .eq('team_id', teamId)
        .eq('valid_date', todayStr)
        .eq('is_active', true)
        .maybeSingle();

    print('[getCurrentFormula] Result: $result');
    return result?['formula'] as String?;
  }

  /// 设置当天的汇率公式
  Future<void> setDailyFormula(String teamId, String formula) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    print('[setDailyFormula] Setting formula for teamId=$teamId, date=$todayStr, formula=$formula');

    // 先将同team_id的今天所有公式is_active设为false
    await _supabase
        .from('exchange_settings')
        .update({'is_active': false})
        .eq('team_id', teamId)
        .eq('valid_date', todayStr);

    print('[setDailyFormula] Deactivated existing formulas');

    // 检查是否已存在相同的公式记录
    final existing = await _supabase
        .from('exchange_settings')
        .select()
        .eq('team_id', teamId)
        .eq('valid_date', todayStr)
        .eq('formula', formula)
        .maybeSingle();

    print('[setDailyFormula] Existing record: $existing');

    if (existing != null) {
      // 如果存在，更新为active
      await _supabase
          .from('exchange_settings')
          .update({'is_active': true}).eq('id', existing['id']);
      print('[setDailyFormula] Updated existing record to active');
    } else {
      // 如果不存在，插入新记录
      final insertResult = await _supabase.from('exchange_settings').insert({
        'team_id': teamId,
        'formula': formula,
        'valid_date': todayStr,
        'is_active': true,
      }).select();
      print('[setDailyFormula] Inserted new record: $insertResult');
    }

    // 同时保存到历史记录
    await _historyService.saveFormula(formula, teamId);
    print('[setDailyFormula] Saved to history');
  }

  /// 使用当前公式计算价格
  Future<double?> calculateWithCurrentFormula(
      String teamId, double rmbPrice) async {
    final formula = await getCurrentFormula(teamId);

    if (formula == null) {
      return null;
    }

    return FormulaCalculator.calculate(formula, rmbPrice);
  }

  /// 更新汇率公式（别名方法，便于调用）
  Future<void> updateFormula(String teamId, String formula) async {
    await setDailyFormula(teamId, formula);
  }
}
