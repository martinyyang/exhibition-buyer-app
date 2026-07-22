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
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = await _supabase
        .from('exchange_settings')
        .select()
        .eq('team_id', teamId)
        .eq('valid_date', todayStr)
        .eq('is_active', true)
        .maybeSingle();

    return result?['formula'] as String?;
  }

  /// 设置当天的汇率公式
  Future<void> setDailyFormula(String teamId, String formula) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 先将同team_id的今天其他公式is_active设为false
    await _supabase
        .from('exchange_settings')
        .update({'is_active': false})
        .eq('team_id', teamId)
        .eq('valid_date', todayStr)
        .neq('formula', formula);

    // 插入新的exchange_setting记录
    await _supabase.from('exchange_settings').insert({
      'team_id': teamId,
      'formula': formula,
      'valid_date': todayStr,
      'is_active': true,
    });

    // 同时保存到历史记录
    await _historyService.saveFormula(formula, teamId);
  }

  /// 使用当前公式计算价格
  Future<double?> calculateWithCurrentFormula(String teamId, double rmbPrice) async {
    final formula = await getCurrentFormula(teamId);

    if (formula == null) {
      return null;
    }

    return FormulaCalculator.calculate(formula, rmbPrice);
  }
}
