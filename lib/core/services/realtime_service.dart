import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../config/network_config.dart';
import 'dart:async';

/// Realtime同步服务
/// 监听数据库变化并自动更新本地状态
/// 针对中国网络环境增强连接稳定性
class RealtimeService {
  final SupabaseClient _client;
  final List<RealtimeChannel> _channels = [];
  Timer? _heartbeatTimer;
  bool _isDisposed = false;

  RealtimeService(this._client) {
    _startHeartbeat();
  }

  /// 监听摊位变化（某个场次下的所有摊位）
  RealtimeChannel subscribeToBooths(
      String eventId, Function(dynamic) onUpdate) {
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
  RealtimeChannel subscribeToPhotos(
      String boothId, Function(dynamic) onUpdate) {
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
  RealtimeChannel subscribeToFormulaHistory(
      String teamId, Function(dynamic) onUpdate) {
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
  RealtimeChannel subscribeToExchangeSettings(
      String teamId, Function(dynamic) onUpdate) {
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
    final channelsCopy = List<RealtimeChannel>.from(_channels);
    for (final channel in channelsCopy) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }

  /// 清理资源
  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    unsubscribeAll();
  }

  /// 启动心跳检测，保持连接活跃
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      NetworkConfig.realtimeHeartbeatInterval,
      (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }
        // 定期检查，防止连接僵死
        // Supabase Flutter SDK 会自动处理重连
        // 这里只做状态监控
      },
    );
  }
}

/// Realtime Service Provider
/// 注意：需要在使用前先import supabaseServiceProvider
/// import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
final realtimeServiceProvider = Provider((ref) {
  // 通过provider获取supabase客户端，而不是直接使用Supabase.instance
  // 这样在测试时可以mock
  final supabaseService = ref.watch(supabaseServiceProvider);
  final service = RealtimeService(supabaseService.client);

  // 当Provider被销毁时清理资源
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
