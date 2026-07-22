import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/realtime_service.dart';
import '../services/formula_history_service.dart';
import '../services/exchange_settings_service.dart';
import '../../auth/providers/auth_provider.dart';

// FormulaHistoryService Provider
final formulaHistoryServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return FormulaHistoryService(supabase.client);
});

// ExchangeSettingsService Provider
final exchangeSettingsServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final historyService = ref.watch(formulaHistoryServiceProvider);
  return ExchangeSettingsService(supabase.client, historyService);
});

// 公式历史记录Provider
class FormulaHistoryNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final FormulaHistoryService _historyService;
  final RealtimeService _realtimeService;
  final String _teamId;
  RealtimeChannel? _channel;

  FormulaHistoryNotifier(
    this._historyService,
    this._realtimeService,
    this._teamId,
  ) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始加载
    await refresh();

    // 订阅实时更新
    _channel = _realtimeService.subscribeToFormulaHistory(_teamId, (payload) {
      // 数据变化时重新加载
      refresh();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final formulas = await _historyService.getRecentFormulas(_teamId);
      state = AsyncValue.data(formulas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _realtimeService.unsubscribe(_channel!);
    }
    super.dispose();
  }
}

// 公式历史记录Provider（按团队）
final formulaHistoryProvider = StateNotifierProvider.family<FormulaHistoryNotifier, AsyncValue<List<String>>, String>(
  (ref, teamId) {
    final historyService = ref.watch(formulaHistoryServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return FormulaHistoryNotifier(historyService, realtimeService, teamId);
  },
);

// 当前活跃公式Provider
class CurrentFormulaNotifier extends StateNotifier<AsyncValue<String?>> {
  final ExchangeSettingsService _settingsService;
  final RealtimeService _realtimeService;
  final String _teamId;
  RealtimeChannel? _channel;

  CurrentFormulaNotifier(
    this._settingsService,
    this._realtimeService,
    this._teamId,
  ) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始加载
    await refresh();

    // 订阅实时更新
    _channel = _realtimeService.subscribeToExchangeSettings(_teamId, (payload) {
      // 数据变化时重新加载
      refresh();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final formula = await _settingsService.getCurrentFormula(_teamId);
      state = AsyncValue.data(formula);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _realtimeService.unsubscribe(_channel!);
    }
    super.dispose();
  }
}

// 当前活跃公式Provider（按团队）
final currentFormulaProvider = StateNotifierProvider.family<CurrentFormulaNotifier, AsyncValue<String?>, String>(
  (ref, teamId) {
    final settingsService = ref.watch(exchangeSettingsServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return CurrentFormulaNotifier(settingsService, realtimeService, teamId);
  },
);
