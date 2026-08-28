import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/event_service.dart';
import '../models/event.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/realtime_service.dart';

// EventService Provider
final eventServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return EventService(supabase.client);
});

// Realtime订阅Provider - 监听events表变化（仅监听当前团队）
// Realtime订阅Provider - 监听 events 表变化（动态按 teamId 订阅）
final eventsRealtimeFamilyProvider =
    StreamProvider.family<void, String>((ref, teamId) async* {
  if (teamId.isEmpty) {
    yield null;
    return;
  }

  final realtimeService = ref.watch(realtimeServiceProvider);
  final controller = StreamController<void>();

  // 通过 RealtimeService 统一管理订阅（订阅与清理保持一致）
  // 仅监听当前团队的 events 表变化
  final channel = realtimeService.subscribeToEvents(teamId, (payload) {
    // 当当前团队的 events 表有变化时，触发刷新
    controller.add(null);
  });

  ref.onDispose(() {
    // 统一走 RealtimeService.unsubscribe：removeChannel 并从内部列表移除
    realtimeService.unsubscribe(channel);
    controller.close();
  });

  yield* controller.stream;
});

// 场次列表Provider（按团队过滤，支持用户/团队变更时动态刷新）
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final user = await ref.watch(currentUserDataProvider.future);
  final teamId = user?.teamId;

  if (teamId == null || teamId.isEmpty) return [];

  // 动态建立与当前 teamId 匹配的 Realtime 通道
  ref.watch(eventsRealtimeFamilyProvider(teamId));

  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEventsByTeam(teamId);
});

// 当前活跃场次Provider（按团队过滤，支持用户/团队变更时动态刷新）
final activeEventProvider = FutureProvider<Event?>((ref) async {
  final user = await ref.watch(currentUserDataProvider.future);
  final teamId = user?.teamId;

  if (teamId == null || teamId.isEmpty) return null;

  // 动态建立与当前 teamId 匹配的 Realtime 通道
  ref.watch(eventsRealtimeFamilyProvider(teamId));

  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getActiveEventByTeam(teamId);
});

// 单个场次Provider
final eventProvider =
    FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEvent(eventId);
});
