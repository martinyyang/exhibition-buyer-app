import 'package:supabase_flutter/supabase_flutter.dart';

class FormulaHistoryService {
  final SupabaseClient _supabase;

  FormulaHistoryService(this._supabase);

  /// 保存公式到历史记录
  Future<void> saveFormula(String formula, String teamId) async {
    // 检查是否已存在
    final existing = await _supabase
        .from('formula_history')
        .select()
        .eq('team_id', teamId)
        .eq('formula', formula)
        .maybeSingle();

    if (existing != null) {
      // 更新使用次数和时间
      await _supabase.from('formula_history').update({
        'last_used_at': DateTime.now().toIso8601String(),
        'use_count': existing['use_count'] + 1,
      }).eq('id', existing['id']);
    } else {
      // 新增记录
      await _supabase.from('formula_history').insert({
        'team_id': teamId,
        'formula': formula,
        'last_used_at': DateTime.now().toIso8601String(),
        'use_count': 1,
      });
    }
  }

  /// 获取最近使用的公式（最多5条）
  Future<List<String>> getRecentFormulas(String teamId) async {
    final result = await _supabase
        .from('formula_history')
        .select('formula')
        .eq('team_id', teamId)
        .order('last_used_at', ascending: false)
        .limit(5);

    return result.map((r) => r['formula'] as String).toList();
  }

  /// 获取使用频率最高的公式
  Future<List<Map<String, dynamic>>> getMostUsedFormulas(
      String teamId, int limit) async {
    final result = await _supabase
        .from('formula_history')
        .select('formula, use_count, last_used_at')
        .eq('team_id', teamId)
        .order('use_count', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(result);
  }

  /// 删除公式历史
  Future<void> deleteFormula(String teamId, String formula) async {
    await _supabase
        .from('formula_history')
        .delete()
        .eq('team_id', teamId)
        .eq('formula', formula);
  }

  /// 根据公式文本查询是否已存在
  Future<Map<String, dynamic>?> getFormulaByText(String teamId, String formula) async {
    final result = await _supabase
        .from('formula_history')
        .select()
        .eq('team_id', teamId)
        .eq('formula', formula)
        .maybeSingle();

    return result;
  }
}
