import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_presence.dart';

/// 用户在线状态服务
class UserPresenceService {
  final SupabaseClient _supabase;

  UserPresenceService(this._supabase);

  /// 更新当前用户的在线状态
  Future<void> updatePresence({
    required String userId,
    required String teamId,
    required String status,
    String? currentScreen,
    Map<String, dynamic>? currentContext,
  }) async {
    await _supabase.from('user_presence').upsert({
      'user_id': userId,
      'team_id': teamId,
      'status': status,
      'last_seen': DateTime.now().toIso8601String(),
      'current_screen': currentScreen,
      'current_context': currentContext,
    });
  }

  /// 设置用户为在线状态
  Future<void> setOnline({
    required String userId,
    required String teamId,
    String? currentScreen,
    Map<String, dynamic>? currentContext,
  }) async {
    await updatePresence(
      userId: userId,
      teamId: teamId,
      status: 'online',
      currentScreen: currentScreen,
      currentContext: currentContext,
    );
  }

  /// 设置用户为离线状态
  Future<void> setOffline({
    required String userId,
    required String teamId,
  }) async {
    await updatePresence(
      userId: userId,
      teamId: teamId,
      status: 'offline',
    );
  }

  /// 获取团队所有在线用户
  Future<List<UserPresence>> getTeamPresence(String teamId) async {
    final response = await _supabase
        .from('user_presence')
        .select('*, users!inner(id, name, email)')
        .eq('team_id', teamId)
        .eq('status', 'online')
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => UserPresence.fromJson(json))
        .toList();
  }

  /// 获取在特定页面的用户
  Future<List<UserPresence>> getUsersOnScreen({
    required String teamId,
    required String screen,
    Map<String, dynamic>? context,
  }) async {
    var query = _supabase
        .from('user_presence')
        .select('*, users!inner(id, name, email)')
        .eq('team_id', teamId)
        .eq('status', 'online')
        .eq('current_screen', screen);

    final response = await query;

    final users =
        (response as List).map((json) => UserPresence.fromJson(json)).toList();

    // 如果有上下文，进一步筛选匹配的用户
    if (context != null && context.isNotEmpty) {
      return users.where((user) {
        if (user.currentContext == null) return false;
        return context.entries.every((entry) {
          return user.currentContext![entry.key] == entry.value;
        });
      }).toList();
    }

    return users;
  }

  /// 订阅团队在线状态变化
  RealtimeChannel subscribeToTeamPresence(
    String teamId,
    void Function(UserPresence presence, String event) onUpdate,
  ) {
    final channel = _supabase
        .channel('team_presence_$teamId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'team_id',
            value: teamId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              final presence = UserPresence.fromJson(data);
              final event = payload.eventType.name;
              onUpdate(presence, event);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// 心跳保活（定期更新 last_seen 时间戳）
  Future<void> heartbeat({
    required String userId,
    required String teamId,
    String? currentScreen,
    Map<String, dynamic>? currentContext,
  }) async {
    await _supabase.from('user_presence').update({
      'last_seen': DateTime.now().toIso8601String(),
      'current_screen': currentScreen,
      'current_context': currentContext,
    }).eq('user_id', userId);
  }
}
