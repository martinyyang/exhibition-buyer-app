import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/event/providers/event_provider.dart';
import 'package:exhibition_buyer_app/features/event/services/event_service.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';
import 'package:exhibition_buyer_app/features/auth/services/auth_service.dart';
import 'package:exhibition_buyer_app/core/services/supabase_client.dart';
import 'dart:async';

// Mock类
class MockEventService extends Mock implements EventService {}
class MockAuthService extends Mock implements AuthService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseService extends Mock implements SupabaseService {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

// 为了测试Realtime，需要创建fake回调
class FakeRealtimeChannel implements RealtimeChannel {
  final List<void Function(PostgresChangePayload)> _callbacks = [];
  bool _isSubscribed = false;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    required String schema,
    required String table,
    required void Function(PostgresChangePayload) callback,
  }) {
    _callbacks.add(callback);
    return this;
  }

  @override
  RealtimeChannel subscribe([void Function(String, Map<String, dynamic>?)? callback]) {
    _isSubscribed = true;
    return this;
  }

  @override
  Future<String> unsubscribe() async {
    _isSubscribed = false;
    return 'ok';
  }

  // 模拟触发数据库变化
  void triggerChange(PostgresChangePayload payload) {
    for (final callback in _callbacks) {
      callback(payload);
    }
  }

  // Implement other required methods with minimal implementation
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockEventService mockEventService;
  late MockAuthService mockAuthService;
  late MockSupabaseService mockSupabaseService;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockEventService = MockEventService();
    mockAuthService = MockAuthService();
    mockSupabaseService = MockSupabaseService();
    mockSupabaseClient = MockSupabaseClient();
  });

  group('EventProvider集成测试', () {
    const testUserId = 'user-123';
    const testTeamId = 'team-456';

    final testEvent1 = Event(
      id: 'event-1',
      createdAt: DateTime(2024, 3, 10),
      name: '深圳珠宝展2024',
      startDate: DateTime(2024, 3, 15),
      endDate: DateTime(2024, 3, 20),
      teamId: testTeamId,
      isActive: true,
    );

    final testEvent2 = Event(
      id: 'event-2',
      createdAt: DateTime(2024, 2, 1),
      name: '上海珠宝展2024',
      startDate: DateTime(2024, 2, 10),
      endDate: DateTime(2024, 2, 15),
      teamId: testTeamId,
      isActive: false,
    );

    group('eventsProvider', () {
      test('返回当前用户的所有场次', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockEventService.getEvents(testUserId))
            .thenAnswer((_) async => [testEvent1, testEvent2]);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final events = await container.read(eventsProvider.future);

        // Assert
        expect(events.length, 2);
        expect(events[0].id, 'event-1');
        expect(events[1].id, 'event-2');
        verify(() => mockEventService.getEvents(testUserId)).called(1);
      });

      test('用户未登录时返回空列表', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(null);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final events = await container.read(eventsProvider.future);

        // Assert
        expect(events, isEmpty);
        verifyNever(() => mockEventService.getEvents(any()));
      });
    });

    group('activeEventProvider', () {
      test('返回当前活跃场次', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockEventService.getActiveEvent(testUserId))
            .thenAnswer((_) async => testEvent1);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final activeEvent = await container.read(activeEventProvider.future);

        // Assert
        expect(activeEvent, isNotNull);
        expect(activeEvent!.id, 'event-1');
        expect(activeEvent.isActive, true);
        verify(() => mockEventService.getActiveEvent(testUserId)).called(1);
      });

      test('没有活跃场次时返回null', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockEventService.getActiveEvent(testUserId))
            .thenAnswer((_) async => null);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final activeEvent = await container.read(activeEventProvider.future);

        // Assert
        expect(activeEvent, isNull);
      });
    });

    group('eventProvider (单个场次)', () {
      test('根据ID获取场次详情', () async {
        // Arrange
        const eventId = 'event-1';
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockEventService.getEvent(eventId))
            .thenAnswer((_) async => testEvent1);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act
        final event = await container.read(eventProvider(eventId).future);

        // Assert
        expect(event, isNotNull);
        expect(event!.id, eventId);
        expect(event.name, '深圳珠宝展2024');
      });
    });

    group('Realtime订阅测试', () {
      test('events表变化时自动刷新eventsProvider', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        // 初始返回一个场次
        when(() => mockEventService.getEvents(testUserId))
            .thenAnswer((_) async => [testEvent1]);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act - 第一次读取
        final events1 = await container.read(eventsProvider.future);
        expect(events1.length, 1);

        // 模拟数据库变化，更新mock返回值
        when(() => mockEventService.getEvents(testUserId))
            .thenAnswer((_) async => [testEvent1, testEvent2]);

        // 触发Realtime变化
        fakeChannel.triggerChange(PostgresChangePayload(
          oldRecord: {},
          newRecord: {},
          schema: 'public',
          table: 'events',
          commitTimestamp: '',
          eventType: PostgresChangeEvent.insert,
          errors: null,
        ));

        // 等待异步更新
        await Future.delayed(Duration(milliseconds: 100));

        // 第二次读取
        final events2 = await container.read(eventsProvider.future);

        // Assert
        expect(events2.length, 2);
        verify(() => mockEventService.getEvents(testUserId)).called(2);
      });

      test('events表变化时自动刷新activeEventProvider', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        // 初始无活跃场次
        when(() => mockEventService.getActiveEvent(testUserId))
            .thenAnswer((_) async => null);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act - 第一次读取
        final activeEvent1 = await container.read(activeEventProvider.future);
        expect(activeEvent1, isNull);

        // 模拟数据库变化，设置活跃场次
        when(() => mockEventService.getActiveEvent(testUserId))
            .thenAnswer((_) async => testEvent1);

        // 触发Realtime变化
        fakeChannel.triggerChange(PostgresChangePayload(
          oldRecord: {},
          newRecord: {},
          schema: 'public',
          table: 'events',
          commitTimestamp: '',
          eventType: PostgresChangeEvent.update,
          errors: null,
        ));

        // 等待异步更新
        await Future.delayed(Duration(milliseconds: 100));

        // 第二次读取
        final activeEvent2 = await container.read(activeEventProvider.future);

        // Assert
        expect(activeEvent2, isNotNull);
        expect(activeEvent2!.isActive, true);
        verify(() => mockEventService.getActiveEvent(testUserId)).called(2);
      });

      test('dispose时取消订阅', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);
        when(() => mockEventService.getEvents(testUserId))
            .thenAnswer((_) async => [testEvent1]);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );

        // Act - 触发订阅
        await container.read(eventsProvider.future);
        expect(fakeChannel._isSubscribed, true);

        // Dispose容器
        container.dispose();

        // 等待dispose完成
        await Future.delayed(Duration(milliseconds: 50));

        // Assert
        expect(fakeChannel._isSubscribed, false);
      });
    });

    group('Provider刷新机制', () {
      test('invalidate后重新加载数据', () async {
        // Arrange
        when(() => mockAuthService.currentUserId).thenReturn(testUserId);
        when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

        final fakeChannel = FakeRealtimeChannel();
        when(() => mockSupabaseClient.channel(any())).thenReturn(fakeChannel);

        when(() => mockEventService.getEvents(testUserId))
            .thenAnswer((_) async => [testEvent1]);

        final container = ProviderContainer(
          overrides: [
            eventServiceProvider.overrideWithValue(mockEventService),
            authServiceProvider.overrideWithValue(mockAuthService),
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
        );
        addTearDown(container.dispose);

        // Act - 第一次读取
        await container.read(eventsProvider.future);

        // 更新mock返回值
        when(() => mockEventService.getEvents(testUserId))
            .thenAnswer((_) async => [testEvent1, testEvent2]);

        // 刷新provider
        container.invalidate(eventsProvider);

        // 第二次读取
        final events = await container.read(eventsProvider.future);

        // Assert
        expect(events.length, 2);
        verify(() => mockEventService.getEvents(testUserId)).called(2);
      });
    });
  });
}
