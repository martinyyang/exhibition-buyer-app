import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../../auth/providers/auth_provider.dart';

// EventService Provider
final eventServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return EventService(supabase.client);
});

// Realtime订阅Provider - 监听events表变化（仅监听当前团队）
final eventsRealtimeProvider = StreamProvider<void>((ref) async* {
  final supabase = ref.watch(supabaseServiceProvider);

  // 获取用户的 team_id
  final user = await ref.watch(currentUserDataProvider.future);
  final teamId = user?.teamId;

  if (teamId == null || teamId.isEmpty) {
    yield null;
    return;
  }

  final controller = StreamController<void>();

  // 订阅events表的变化，仅监听当前团队
  final channel = supabase.client
      .channel('events_changes_$teamId')
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
          // 当当前团队的events表有变化时，触发刷新
          controller.add(null);
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
});

// 场次列表Provider（按团队过滤，支持Realtime自动刷新）
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  // 监听Realtime变化（建立依赖关系）
  ref.watch(eventsRealtimeProvider);

  final user = await ref.watch(currentUserDataProvider.future);
  final teamId = user?.teamId;

  if (teamId == null || teamId.isEmpty) return [];

  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEventsByTeam(teamId);
});

// 当前活跃场次Provider（支持Realtime自动刷新）
final activeEventProvider = FutureProvider<Event?>((ref) async {
  // 监听Realtime变化（建立依赖关系）
  ref.watch(eventsRealtimeProvider);

  final user = await ref.watch(currentUserDataProvider.future);
  final teamId = user?.teamId;

  if (teamId == null || teamId.isEmpty) return null;

  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getActiveEventByTeam(teamId);
});

// 单个场次Provider
final eventProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  // 监听Realtime变化（建立依赖关系）
  ref.watch(eventsRealtimeProvider);

  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEvent(eventId);
});
