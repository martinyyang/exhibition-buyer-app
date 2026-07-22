import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/formula/providers/formula_provider.dart';
import 'package:exhibition_buyer_app/features/formula/services/formula_history_service.dart';
import 'package:exhibition_buyer_app/features/formula/services/exchange_settings_service.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';

@GenerateMocks([FormulaHistoryService, ExchangeSettingsService, RealtimeService])
import 'formula_provider_test.mocks.dart';

void main() {
  late MockFormulaHistoryService mockHistoryService;
  late MockExchangeSettingsService mockSettingsService;
  late MockRealtimeService mockRealtimeService;

  setUp(() {
    mockHistoryService = MockFormulaHistoryService();
    mockSettingsService = MockExchangeSettingsService();
    mockRealtimeService = MockRealtimeService();
  });

  group('FormulaHistoryNotifier', () {
    test('初始化时加载公式历史', () async {
      final teamId = 'team-123';
      final formulas = ['RMB * 0.14', '(RMB - 50) * 0.14', 'RMB * 0.15'];

      when(mockHistoryService.getRecentFormulas(teamId))
          .thenAnswer((_) async => formulas);
      when(mockRealtimeService.subscribeToFormulaHistory(teamId, any))
          .thenReturn(null);

      final notifier = FormulaHistoryNotifier(
        mockHistoryService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      expect(notifier.state.value, formulas);
      verify(mockHistoryService.getRecentFormulas(teamId)).called(1);
    });

    test('订阅Realtime更新', () async {
      final teamId = 'team-123';

      when(mockHistoryService.getRecentFormulas(teamId))
          .thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFormulaHistory(teamId, any))
          .thenReturn(null);

      FormulaHistoryNotifier(
        mockHistoryService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockRealtimeService.subscribeToFormulaHistory(teamId, any)).called(1);
    });

    test('refresh时重新加载数据', () async {
      final teamId = 'team-123';
      final formulas = ['RMB * 0.14'];

      when(mockHistoryService.getRecentFormulas(teamId))
          .thenAnswer((_) async => formulas);
      when(mockRealtimeService.subscribeToFormulaHistory(teamId, any))
          .thenReturn(null);

      final notifier = FormulaHistoryNotifier(
        mockHistoryService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      // 调用refresh
      await notifier.refresh();

      verify(mockHistoryService.getRecentFormulas(teamId)).called(2);
    });

    test('加载失败时设置错误状态', () async {
      final teamId = 'team-123';
      final error = Exception('网络错误');

      when(mockHistoryService.getRecentFormulas(teamId))
          .thenThrow(error);
      when(mockRealtimeService.subscribeToFormulaHistory(teamId, any))
          .thenReturn(null);

      final notifier = FormulaHistoryNotifier(
        mockHistoryService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error, error);
    });
  });

  group('CurrentFormulaNotifier', () {
    test('初始化时加载当前公式', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';

      when(mockSettingsService.getCurrentFormula(teamId))
          .thenAnswer((_) async => formula);
      when(mockRealtimeService.subscribeToExchangeSettings(teamId, any))
          .thenReturn(null);

      final notifier = CurrentFormulaNotifier(
        mockSettingsService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      expect(notifier.state.value, formula);
      verify(mockSettingsService.getCurrentFormula(teamId)).called(1);
    });

    test('当天没有公式时返回null', () async {
      final teamId = 'team-123';

      when(mockSettingsService.getCurrentFormula(teamId))
          .thenAnswer((_) async => null);
      when(mockRealtimeService.subscribeToExchangeSettings(teamId, any))
          .thenReturn(null);

      final notifier = CurrentFormulaNotifier(
        mockSettingsService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      expect(notifier.state.value, isNull);
    });

    test('订阅Realtime更新', () async {
      final teamId = 'team-123';

      when(mockSettingsService.getCurrentFormula(teamId))
          .thenAnswer((_) async => null);
      when(mockRealtimeService.subscribeToExchangeSettings(teamId, any))
          .thenReturn(null);

      CurrentFormulaNotifier(
        mockSettingsService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockRealtimeService.subscribeToExchangeSettings(teamId, any)).called(1);
    });

    test('refresh时重新加载数据', () async {
      final teamId = 'team-123';
      final formula = 'RMB * 0.14';

      when(mockSettingsService.getCurrentFormula(teamId))
          .thenAnswer((_) async => formula);
      when(mockRealtimeService.subscribeToExchangeSettings(teamId, any))
          .thenReturn(null);

      final notifier = CurrentFormulaNotifier(
        mockSettingsService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      // 调用refresh
      await notifier.refresh();

      verify(mockSettingsService.getCurrentFormula(teamId)).called(2);
    });

    test('加载失败时设置错误状态', () async {
      final teamId = 'team-123';
      final error = Exception('网络错误');

      when(mockSettingsService.getCurrentFormula(teamId))
          .thenThrow(error);
      when(mockRealtimeService.subscribeToExchangeSettings(teamId, any))
          .thenReturn(null);

      final notifier = CurrentFormulaNotifier(
        mockSettingsService,
        mockRealtimeService,
        teamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error, error);
    });
  });

  group('Provider Integration', () {
    test('formulaHistoryProvider创建FormulaHistoryNotifier', () {
      final container = ProviderContainer(
        overrides: [
          formulaHistoryServiceProvider.overrideWithValue(mockHistoryService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      when(mockHistoryService.getRecentFormulas(any))
          .thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFormulaHistory(any, any))
          .thenReturn(null);

      final notifier = container.read(formulaHistoryProvider('team-123').notifier);

      expect(notifier, isA<FormulaHistoryNotifier>());

      container.dispose();
    });

    test('currentFormulaProvider创建CurrentFormulaNotifier', () {
      final container = ProviderContainer(
        overrides: [
          exchangeSettingsServiceProvider.overrideWithValue(mockSettingsService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      when(mockSettingsService.getCurrentFormula(any))
          .thenAnswer((_) async => null);
      when(mockRealtimeService.subscribeToExchangeSettings(any, any))
          .thenReturn(null);

      final notifier = container.read(currentFormulaProvider('team-123').notifier);

      expect(notifier, isA<CurrentFormulaNotifier>());

      container.dispose();
    });
  });
}
