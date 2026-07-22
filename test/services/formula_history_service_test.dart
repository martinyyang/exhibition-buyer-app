import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/formula/services/formula_history_service.dart';

@GenerateMocks([SupabaseClient, PostgrestFilterBuilder, PostgrestTransformBuilder])
import 'formula_history_service_test.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late FormulaHistoryService historyService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    historyService = FormulaHistoryService(mockSupabase);
  });

  group('FormulaHistoryService - saveFormula', () {
    test('首次保存公式时创建新记录', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      // Mock查询（返回null表示不存在）
      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('formula', formula)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      // Mock插入
      when(mockFilterBuilder.insert(any)).thenAnswer((_) async => null);

      await historyService.saveFormula(formula, teamId);

      verify(mockFilterBuilder.insert(argThat(predicate((Map<String, dynamic> data) {
        return data['team_id'] == teamId &&
            data['formula'] == formula &&
            data['use_count'] == 1;
      })))).called(1);
    });

    test('重复保存公式时更新使用次数', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';
      final existingId = 'history-1';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      // Mock查询（返回已存在的记录）
      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('formula', formula)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
            'id': existingId,
            'team_id': teamId,
            'formula': formula,
            'use_count': 3,
            'last_used_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
          });

      // Mock更新
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', existingId)).thenAnswer((_) async => null);

      await historyService.saveFormula(formula, teamId);

      verify(mockFilterBuilder.update(argThat(predicate((Map<String, dynamic> data) {
        return data['use_count'] == 4 && data['last_used_at'] != null;
      })))).called(1);
    });

    test('保存时自动更新last_used_at', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('formula', formula)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      when(mockFilterBuilder.insert(any)).thenAnswer((_) async => null);

      await historyService.saveFormula(formula, teamId);

      verify(mockFilterBuilder.insert(argThat(predicate((Map<String, dynamic> data) {
        final lastUsedAt = DateTime.parse(data['last_used_at']);
        return lastUsedAt.difference(now).inSeconds.abs() < 5;
      })))).called(1);
    });
  });

  group('FormulaHistoryService - getRecentFormulas', () {
    test('获取最近使用的5条公式', () async {
      final teamId = 'team-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('formula')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('last_used_at', ascending: false))
          .thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.limit(5)).thenAnswer((_) async => [
            {'formula': 'RMB * 0.14'},
            {'formula': '(RMB - 50) * 0.14'},
            {'formula': 'RMB * 0.15 + 10'},
            {'formula': 'RMB / 7'},
            {'formula': 'RMB * 0.13'},
          ]);

      final formulas = await historyService.getRecentFormulas(teamId);

      expect(formulas.length, 5);
      expect(formulas[0], 'RMB * 0.14');
      expect(formulas[4], 'RMB * 0.13');
    });

    test('团队没有历史记录时返回空列表', () async {
      final teamId = 'team-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('formula')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('last_used_at', ascending: false))
          .thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.limit(5)).thenAnswer((_) async => []);

      final formulas = await historyService.getRecentFormulas(teamId);

      expect(formulas, isEmpty);
    });

    test('历史记录按last_used_at降序排列', () async {
      final teamId = 'team-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('formula')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('last_used_at', ascending: false))
          .thenReturn(mockTransformBuilder);

      verify(mockFilterBuilder.order('last_used_at', ascending: false)).called(1);
    });
  });

  group('FormulaHistoryService - deleteFormula', () {
    test('成功删除指定公式', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.delete()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('formula', formula)).thenAnswer((_) async => null);

      await historyService.deleteFormula(teamId, formula);

      verify(mockFilterBuilder.delete()).called(1);
      verify(mockFilterBuilder.eq('team_id', teamId)).called(1);
      verify(mockFilterBuilder.eq('formula', formula)).called(1);
    });
  });

  group('FormulaHistoryService - getFormulaByText', () {
    test('查询存在的公式返回记录', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('formula', formula)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
            'id': 'history-1',
            'team_id': teamId,
            'formula': formula,
            'use_count': 5,
            'last_used_at': DateTime.now().toIso8601String(),
          });

      final result = await historyService.getFormulaByText(teamId, formula);

      expect(result, isNotNull);
      expect(result!['formula'], formula);
      expect(result['use_count'], 5);
    });

    test('查询不存在的公式返回null', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.99';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('formula_history')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('formula', formula)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      final result = await historyService.getFormulaByText(teamId, formula);

      expect(result, isNull);
    });
  });
}
