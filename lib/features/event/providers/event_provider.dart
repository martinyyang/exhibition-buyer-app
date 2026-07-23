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

// Realtime订阅Provider - 监听events表变化
final eventsRealtimeProvider = StreamProvider<void>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final authService = ref.watch(authServiceProvider);

  final userId = authService.currentUserId;
  if (userId == null) {
    return Stream.value(null);
  }

  final controller = StreamController<void>();

  // 订阅events表的变化
  final channel = supabase.client
      .channel('events_changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'events',
        callback: (payload) {
          // 当events表有任何变化时，触发刷新
          controller.add(null);
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

// 场次列表Provider（按团队过滤，支持Realtime自动刷新）
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  // 监听Realtime变化（建立依赖关系）
  ref.watch(eventsRealtimeProvider);

  final eventService = ref.watch(eventServiceProvider);
  final authService = ref.watch(authServiceProvider);

  final userId = authService.currentUserId;
  if (userId == null) return [];

  return await eventService.getEvents(userId);
});

// 当前活跃场次Provider（支持Realtime自动刷新）
final activeEventProvider = FutureProvider<Event?>((ref) async {
  // 监听Realtime变化（建立依赖关系）
  ref.watch(eventsRealtimeProvider);

  final eventService = ref.watch(eventServiceProvider);
  final authService = ref.watch(authServiceProvider);

  final userId = authService.currentUserId;
  if (userId == null) return null;

  return await eventService.getActiveEvent(userId);
});

// 单个场次Provider
final eventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  // 监听Realtime变化（建立依赖关系）
  ref.watch(eventsRealtimeProvider);

  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEvent(eventId);
});
