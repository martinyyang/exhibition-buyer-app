import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/realtime_service.dart';
import '../services/booth_service.dart';
import '../models/booth.dart';
import '../../auth/providers/auth_provider.dart';

// Supabase Service Provider
final supabaseServiceProvider = Provider((ref) {
  return Supabase.instance;
});

// BoothService Provider
final boothServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return BoothService(supabase.client);
});

// 摊位列表状态管理（支持实时同步）
class BoothsNotifier extends StateNotifier<AsyncValue<List<Booth>>> {
  final BoothService _boothService;
  final RealtimeService _realtimeService;
  final String _eventId;
  final String _teamId;
  RealtimeChannel? _channel;

  BoothsNotifier(
    this._boothService,
    this._realtimeService,
    this._eventId,
    this._teamId,
  ) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始加载
    await refresh();

    // 订阅实时更新
    _channel = _realtimeService.subscribeToBooths(_eventId, (payload) {
      // 数据变化时重新加载
      refresh();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final booths = await _boothService.getBooths(
        eventId: _eventId,
        teamId: _teamId,
      );
      state = AsyncValue.data(booths);
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

// 摊位列表Provider Family参数
class BoothsParams {
  final String eventId;
  final String teamId;

  BoothsParams({
    required this.eventId,
    required this.teamId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoothsParams &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          teamId == other.teamId;

  @override
  int get hashCode => eventId.hashCode ^ teamId.hashCode;
}

// 摊位列表Provider（按场次和团队过滤，支持实时同步）
final boothsProvider = StateNotifierProvider.family<BoothsNotifier,
    AsyncValue<List<Booth>>, BoothsParams>(
  (ref, params) {
    final boothService = ref.watch(boothServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return BoothsNotifier(
      boothService,
      realtimeService,
      params.eventId,
      params.teamId,
    );
  },
);

// 向后兼容的简化版本（仅eventId，不推荐使用）
@Deprecated('Use boothsProvider with BoothsParams for data isolation')
final boothsByEventProvider = StateNotifierProvider.family<BoothsNotifier,
    AsyncValue<List<Booth>>, String>(
  (ref, eventId) {
    final boothService = ref.watch(boothServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    // 这里需要从auth获取teamId，暂时使用空字符串
    return BoothsNotifier(boothService, realtimeService, eventId, '');
  },
);

// 单个摊位Provider
final boothProvider = FutureProvider.family<Booth?, String>((ref, boothId) async {
  final boothService = ref.watch(boothServiceProvider);
  return await boothService.getBooth(boothId);
});
