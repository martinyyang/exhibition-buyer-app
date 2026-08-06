import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/realtime_service.dart';
import '../services/user_presence_service.dart';
import '../models/user_presence.dart';
import '../../auth/providers/auth_provider.dart';

// UserPresenceService Provider
final userPresenceServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return UserPresenceService(supabase.client);
});

// 团队在线用户列表 Provider
class TeamPresenceNotifier
    extends StateNotifier<AsyncValue<List<UserPresence>>> {
  final UserPresenceService _presenceService;
  final RealtimeService _realtimeService;
  final String _teamId;
  RealtimeChannel? _channel;

  TeamPresenceNotifier(
    this._presenceService,
    this._realtimeService,
    this._teamId,
  ) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await refresh();

    // 订阅实时更新
    _channel =
        _presenceService.subscribeToTeamPresence(_teamId, (presence, event) {
      // 状态变化时重新加载
      refresh();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final presences = await _presenceService.getTeamPresence(_teamId);
      state = AsyncValue.data(presences);
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

// 团队在线状态 Provider（按团队）
final teamPresenceProvider = StateNotifierProvider.family<TeamPresenceNotifier,
    AsyncValue<List<UserPresence>>, String>(
  (ref, teamId) {
    final presenceService = ref.watch(userPresenceServiceProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return TeamPresenceNotifier(presenceService, realtimeService, teamId);
  },
);

// 特定页面在线用户 Provider
final screenPresenceProvider =
    FutureProvider.family<List<UserPresence>, ScreenPresenceParams>(
  (ref, params) async {
    final presenceService = ref.watch(userPresenceServiceProvider);
    return presenceService.getUsersOnScreen(
      teamId: params.teamId,
      screen: params.screen,
      context: params.context,
    );
  },
);

class ScreenPresenceParams {
  final String teamId;
  final String screen;
  final Map<String, dynamic>? context;

  ScreenPresenceParams({
    required this.teamId,
    required this.screen,
    this.context,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenPresenceParams &&
        other.teamId == teamId &&
        other.screen == screen &&
        other.context.toString() == context.toString();
  }

  @override
  int get hashCode => Object.hash(teamId, screen, context.toString());
}
