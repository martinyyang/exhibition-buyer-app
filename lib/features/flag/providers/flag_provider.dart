import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/realtime_service.dart';
import '../services/flag_service.dart';
import '../models/flag.dart';
import '../../auth/providers/auth_provider.dart';

// FlagService Provider
final flagServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return FlagService(supabase.client);
});

// 旗子列表状态管理（支持实时同步）
class FlagsNotifier extends StateNotifier<AsyncValue<List<Flag>>> {
  final FlagService _flagService;
  final RealtimeService _realtimeService;
  final String _photoId;
  RealtimeChannel? _channel;

  FlagsNotifier(
    this._flagService,
    this._realtimeService,
    this._photoId,
  ) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始加载
    await refresh();

    // 订阅实时更新 - 优化：只更新变化的flag，不重新加载整个列表
    _channel = _realtimeService.subscribeToFlags(_photoId, (payload) {
      // 智能更新：只修改变化的flag，避免整体刷新
      final currentState = state;
      if (currentState is AsyncData<List<Flag>>) {
        final currentFlags = currentState.value;

        // Supabase payload 结构: eventType (INSERT/UPDATE/DELETE)
        final eventType = payload.eventType;

        if (eventType == PostgresChangeEvent.update) {
          // 更新已有flag
          final updatedFlag = Flag.fromJson(payload.newRecord);
          final updatedList = currentFlags.map((flag) {
            return flag.id == updatedFlag.id ? updatedFlag : flag;
          }).toList();
          state = AsyncValue.data(updatedList);
        } else if (eventType == PostgresChangeEvent.insert) {
          // 添加新flag - 检查是否有临时flag需要替换
          final newFlag = Flag.fromJson(payload.newRecord);

          // 查找是否有临时flag（id以'temp_'开头且位置相近）
          final tempFlagIndex = currentFlags.indexWhere((f) =>
            f.id.startsWith('temp_') &&
            (f.positionX - newFlag.positionX).abs() < 0.01 &&
            (f.positionY - newFlag.positionY).abs() < 0.01
          );

          List<Flag> updatedList;
          if (tempFlagIndex != -1) {
            // 替换临时flag
            updatedList = [...currentFlags];
            updatedList[tempFlagIndex] = newFlag;
          } else {
            // 添加新flag（没有对应的临时flag）
            updatedList = [...currentFlags, newFlag];
          }
          updatedList.sort((a, b) => a.number.compareTo(b.number));
          state = AsyncValue.data(updatedList);
        } else if (eventType == PostgresChangeEvent.delete) {
          // 删除flag
          final deletedId = payload.oldRecord['id'] as String;
          final updatedList =
              currentFlags.where((f) => f.id != deletedId).toList();
          state = AsyncValue.data(updatedList);
        }
      } else {
        // 如果状态不是data，则重新加载
        refresh();
      }
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final flags = await _flagService.getFlags(_photoId);
      state = AsyncValue.data(flags);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 添加临时旗子（乐观更新）
  /// 用于在等待服务器响应时立即显示旗子
  void addOptimistic(Flag flag) {
    final currentState = state;
    if (currentState is AsyncData<List<Flag>>) {
      final updatedList = [...currentState.value, flag];
      state = AsyncValue.data(updatedList);
    }
  }

  /// 替换临时旗子为真实旗子
  /// 当服务器返回真实数据时，用真实旗子替换临时旗子
  void replaceOptimistic(String tempId, Flag realFlag) {
    final currentState = state;
    if (currentState is AsyncData<List<Flag>>) {
      final updatedList = currentState.value.map((flag) {
        return flag.id == tempId ? realFlag : flag;
      }).toList();
      // 按编号重新排序
      updatedList.sort((a, b) => a.number.compareTo(b.number));
      state = AsyncValue.data(updatedList);
    }
  }

  /// 移除临时旗子（失败回滚）
  /// 当服务器请求失败时，移除临时显示的旗子
  void removeOptimistic(String tempId) {
    final currentState = state;
    if (currentState is AsyncData<List<Flag>>) {
      final updatedList =
          currentState.value.where((f) => f.id != tempId).toList();
      state = AsyncValue.data(updatedList);
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

// 旗子列表Provider（按照片过滤，支持实时同步）
final flagsProvider =
    StateNotifierProvider.family<FlagsNotifier, AsyncValue<List<Flag>>, String>(
  (ref, photoId) {
    final flagService = ref.watch(flagServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return FlagsNotifier(flagService, realtimeService, photoId);
  },
);

// 单个旗子Provider
final flagProvider = FutureProvider.family<Flag?, String>((ref, flagId) async {
  final flagService = ref.watch(flagServiceProvider);
  return await flagService.getFlag(flagId);
});

// 需要注意的旗子数量Provider（整个团队）
final attentionFlagsCountProvider = FutureProvider<int>((ref) async {
  final authService = ref.watch(authServiceProvider);

  final userId = authService.currentUserId;
  if (userId == null) return 0;

  // TODO: 实现获取需要注意的旗子数量
  return 0;
});

// 单张照片的旗子数量Provider
final photoFlagCountProvider =
    FutureProvider.family<int, String>((ref, photoId) async {
  final flagService = ref.watch(flagServiceProvider);
  final flags = await flagService.getFlags(photoId);
  return flags.length;
});
