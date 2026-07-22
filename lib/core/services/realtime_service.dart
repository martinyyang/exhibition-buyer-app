import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Realtime同步服务
/// 监听数据库变化并自动更新本地状态
class RealtimeService {
  final SupabaseClient _client;
  final List<RealtimeChannel> _channels = [];

  RealtimeService(this._client);

  /// 监听摊位变化（某个场次下的所有摊位）
  RealtimeChannel subscribeToBooths(String eventId, Function(dynamic) onUpdate) {
    final channel = _client
        .channel('booths:$eventId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booths',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// 监听照片变化（某个摊位下的所有照片）
  RealtimeChannel subscribeToPhotos(String boothId, Function(dynamic) onUpdate) {
    final channel = _client
        .channel('photos:$boothId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'photos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booth_id',
            value: boothId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// 监听旗子变化（某张照片下的所有旗子）
  RealtimeChannel subscribeToFlags(String photoId, Function(dynamic) onUpdate) {
    final channel = _client
        .channel('flags:$photoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'flags',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'photo_id',
            value: photoId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// 监听场次变化（某个团队下的所有场次）
  RealtimeChannel subscribeToEvents(String teamId, Function(dynamic) onUpdate) {
    final channel = _client
        .channel('events:$teamId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'team_id',
            value: teamId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// 监听公式历史变化（某个团队的公式历史）
  RealtimeChannel subscribeToFormulaHistory(String teamId, Function(dynamic) onUpdate) {
    final channel = _client
        .channel('formula_history:$teamId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'formula_history',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'team_id',
            value: teamId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// 监听汇率设置变化（某个团队的汇率设置）
  RealtimeChannel subscribeToExchangeSettings(String teamId, Function(dynamic) onUpdate) {
    final channel = _client
        .channel('exchange_settings:$teamId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exchange_settings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'team_id',
            value: teamId,
          ),
          callback: (payload) {
            onUpdate(payload);
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// 取消订阅某个channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
    _channels.remove(channel);
  }

  /// 取消所有订阅
  Future<void> unsubscribeAll() async {
    for (final channel in _channels) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }

  /// 清理资源
  void dispose() {
    unsubscribeAll();
  }
}

/// Realtime Service Provider
final realtimeServiceProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final service = RealtimeService(supabase);

  // 当Provider被销毁时清理资源
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
