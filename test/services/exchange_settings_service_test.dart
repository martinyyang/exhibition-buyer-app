import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/formula/services/exchange_settings_service.dart';
import 'package:exhibition_buyer_app/features/formula/services/formula_history_service.dart';

@GenerateMocks([SupabaseClient, PostgrestFilterBuilder, PostgrestTransformBuilder, FormulaHistoryService])
import 'exchange_settings_service_test.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockFormulaHistoryService mockHistoryService;
  late ExchangeSettingsService settingsService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockHistoryService = MockFormulaHistoryService();
    settingsService = ExchangeSettingsService(mockSupabase, mockHistoryService);
  });

  group('ExchangeSettingsService - getCurrentFormula', () {
    test('获取当天活跃的汇率公式', () async {
      final teamId = 'team-123';
      final today = DateTime.now();
      final formula = 'RMB * 0.14';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
            'id': 'setting-1',
            'team_id': teamId,
            'formula': formula,
            'valid_date': today.toIso8601String().split('T')[0],
            'is_active': true,
            'created_at': today.toIso8601String(),
          });

      final result = await settingsService.getCurrentFormula(teamId);

      expect(result, formula);
    });

    test('当天没有设置公式时返回null', () async {
      final teamId = 'team-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      final result = await settingsService.getCurrentFormula(teamId);

      expect(result, isNull);
    });

    test('只返回is_active为true的公式', () async {
      final teamId = 'team-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);

      verify(mockFilterBuilder.eq('is_active', true)).called(1);
    });
  });

  group('ExchangeSettingsService - setDailyFormula', () {
    test('设置当天公式时禁用其他公式', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';
      final today = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);

      // Mock禁用其他公式
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.neq('formula', formula)).thenAnswer((_) async => null);

      // Mock插入新公式
      when(mockFilterBuilder.insert(any)).thenAnswer((_) async => {
            'id': 'setting-1',
            'team_id': teamId,
            'formula': formula,
            'valid_date': today.toIso8601String().split('T')[0],
            'is_active': true,
            'created_at': today.toIso8601String(),
          });

      // Mock保存到历史
      when(mockHistoryService.saveFormula(formula, teamId)).thenAnswer((_) async => {});

      await settingsService.setDailyFormula(teamId, formula);

      verify(mockFilterBuilder.update({'is_active': false})).called(1);
      verify(mockHistoryService.saveFormula(formula, teamId)).called(1);
    });

    test('设置新公式时自动保存到历史记录', () async {
      final teamId = 'team-123';
      final formula = '(RMB - 50) * 0.14';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.neq('formula', formula)).thenAnswer((_) async => null);

      when(mockFilterBuilder.insert(any)).thenAnswer((_) async => {
            'id': 'setting-1',
            'team_id': teamId,
            'formula': formula,
            'valid_date': DateTime.now().toIso8601String().split('T')[0],
            'is_active': true,
          });

      when(mockHistoryService.saveFormula(formula, teamId)).thenAnswer((_) async => {});

      await settingsService.setDailyFormula(teamId, formula);

      verify(mockHistoryService.saveFormula(formula, teamId)).called(1);
    });

    test('插入的公式记录is_active为true', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.neq('formula', formula)).thenAnswer((_) async => null);

      when(mockFilterBuilder.insert(any)).thenAnswer((_) async => {
            'id': 'setting-1',
            'team_id': teamId,
            'formula': formula,
            'is_active': true,
          });

      when(mockHistoryService.saveFormula(formula, teamId)).thenAnswer((_) async => {});

      await settingsService.setDailyFormula(teamId, formula);

      verify(mockFilterBuilder.insert(argThat(predicate((Map<String, dynamic> data) {
        return data['is_active'] == true &&
            data['formula'] == formula &&
            data['team_id'] == teamId;
      })))).called(1);
    });

    test('设置公式时使用当天日期', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.neq('formula', formula)).thenAnswer((_) async => null);

      when(mockFilterBuilder.insert(any)).thenAnswer((_) async => {
            'id': 'setting-1',
            'team_id': teamId,
            'formula': formula,
            'valid_date': todayStr,
            'is_active': true,
          });

      when(mockHistoryService.saveFormula(formula, teamId)).thenAnswer((_) async => {});

      await settingsService.setDailyFormula(teamId, formula);

      verify(mockFilterBuilder.insert(argThat(predicate((Map<String, dynamic> data) {
        return data['valid_date'] == todayStr;
      })))).called(1);
    });
  });

  group('ExchangeSettingsService - calculateWithCurrentFormula', () {
    test('使用当前公式计算价格', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';
      final rmbPrice = 1000.0;

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
            'formula': formula,
          });

      final result = await settingsService.calculateWithCurrentFormula(teamId, rmbPrice);

      expect(result, 140.0);
    });

    test('使用复杂公式计算价格', () async {
      final teamId = 'team-123';
      final formula = '(RMB - 50) * 0.14 + 10';
      final rmbPrice = 1000.0;

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
            'formula': formula,
          });

      final result = await settingsService.calculateWithCurrentFormula(teamId, rmbPrice);

      expect(result, 143.0);
    });

    test('没有当前公式时返回null', () async {
      final teamId = 'team-123';
      final rmbPrice = 1000.0;

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      final result = await settingsService.calculateWithCurrentFormula(teamId, rmbPrice);

      expect(result, isNull);
    });

    test('公式计算错误时抛出异常', () async {
      final teamId = 'team-123';
      final formula = 'RMB / 0'; // 除以0
      final rmbPrice = 1000.0;

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('exchange_settings')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('team_id', teamId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('valid_date', any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('is_active', true)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {
            'formula': formula,
          });

      expect(
        () => settingsService.calculateWithCurrentFormula(teamId, rmbPrice),
        throwsException,
      );
    });
  });
}
