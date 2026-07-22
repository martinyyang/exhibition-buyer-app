import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/booth/providers/booth_provider.dart';
import 'package:exhibition_buyer_app/features/booth/services/booth_service.dart';
import 'package:exhibition_buyer_app/features/booth/models/booth.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';

@GenerateMocks([BoothService, RealtimeService, RealtimeChannel])
import 'booth_provider_test.mocks.dart';

void main() {
  late MockBoothService mockBoothService;
  late MockRealtimeService mockRealtimeService;
  late MockRealtimeChannel mockChannel;

  setUp(() {
    mockBoothService = MockBoothService();
    mockRealtimeService = MockRealtimeService();
    mockChannel = MockRealtimeChannel();
  });

  group('BoothProvider集成测试', () {
    const testEventId = 'event-123';
    const testTeamId = 'team-456';
    const testBoothId = 'booth-001';

    final testBooth = Booth(
      id: testBoothId,
      boothNumber: 'B01',
      eventId: testEventId,
      teamId: testTeamId,
      createdBy: 'user-789',
      createdAt: DateTime.parse('2026-07-22T10:00:00Z'),
    );

    test('BoothsNotifier初始加载数据', () async {
      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenAnswer((_) async => [testBooth]);

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenReturn(mockChannel);

      final notifier = BoothsNotifier(
        mockBoothService,
        mockRealtimeService,
        testEventId,
        testTeamId,
      );

      // 等待初始化完成
      await Future.delayed(Duration.zero);

      expect(notifier.state.hasValue, isTrue);
      expect(notifier.state.value?.length, 1);
      expect(notifier.state.value?.first.boothNumber, 'B01');

      verify(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).called(1);
      verify(mockRealtimeService.subscribeToBooths(testEventId, any)).called(1);
    });

    test('BoothsNotifier订阅Realtime更新', () async {
      Function(dynamic)? callback;

      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenAnswer((_) async => [testBooth]);

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenAnswer((invocation) {
        callback = invocation.positionalArguments[1] as Function(dynamic);
        return mockChannel;
      });

      final notifier = BoothsNotifier(
        mockBoothService,
        mockRealtimeService,
        testEventId,
        testTeamId,
      );

      await Future.delayed(Duration.zero);

      // 清除初始调用计数
      clearInteractions(mockBoothService);

      // 模拟Realtime事件触发
      expect(callback, isNotNull);
      callback!({'event': 'INSERT'});

      await Future.delayed(Duration.zero);

      // 验证refresh被触发，导致再次调用getBooths
      verify(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).called(1);
    });

    test('BoothsNotifier处理加载错误', () async {
      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenThrow(Exception('Network error'));

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenReturn(mockChannel);

      final notifier = BoothsNotifier(
        mockBoothService,
        mockRealtimeService,
        testEventId,
        testTeamId,
      );

      await Future.delayed(Duration.zero);

      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error.toString(), contains('Network error'));
    });

    test('BoothsNotifier清理Realtime订阅', () async {
      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenAnswer((_) async => [testBooth]);

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenReturn(mockChannel);

      when(mockRealtimeService.unsubscribe(mockChannel))
          .thenAnswer((_) async => {});

      final notifier = BoothsNotifier(
        mockBoothService,
        mockRealtimeService,
        testEventId,
        testTeamId,
      );

      await Future.delayed(Duration.zero);

      notifier.dispose();

      verify(mockRealtimeService.unsubscribe(mockChannel)).called(1);
    });

    test('BoothsNotifier refresh方法手动刷新数据', () async {
      final updatedBooth = testBooth.copyWith(boothNumber: 'B02');

      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenAnswer((_) async => [testBooth]);

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenReturn(mockChannel);

      final notifier = BoothsNotifier(
        mockBoothService,
        mockRealtimeService,
        testEventId,
        testTeamId,
      );

      await Future.delayed(Duration.zero);

      expect(notifier.state.value?.first.boothNumber, 'B01');

      // 更新mock返回值
      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenAnswer((_) async => [updatedBooth]);

      await notifier.refresh();

      expect(notifier.state.value?.first.boothNumber, 'B02');
    });

    test('BoothsParams相等性比较', () {
      final params1 = BoothsParams(eventId: testEventId, teamId: testTeamId);
      final params2 = BoothsParams(eventId: testEventId, teamId: testTeamId);
      final params3 = BoothsParams(eventId: 'other-event', teamId: testTeamId);

      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1, isNot(equals(params3)));
    });

    test('boothsProvider使用正确的参数创建Notifier', () async {
      final container = ProviderContainer(
        overrides: [
          boothServiceProvider.overrideWithValue(mockBoothService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      when(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).thenAnswer((_) async => [testBooth]);

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenReturn(mockChannel);

      final params = BoothsParams(eventId: testEventId, teamId: testTeamId);
      final state = container.read(boothsProvider(params));

      expect(state, isA<AsyncLoading>());

      await Future.delayed(Duration.zero);

      verify(mockBoothService.getBooths(
        eventId: testEventId,
        teamId: testTeamId,
      )).called(1);

      container.dispose();
    });

    test('不同的BoothsParams创建独立的Provider实例', () async {
      final container = ProviderContainer(
        overrides: [
          boothServiceProvider.overrideWithValue(mockBoothService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      when(mockBoothService.getBooths(
        eventId: any,
        teamId: any,
      )).thenAnswer((_) async => [testBooth]);

      when(mockRealtimeService.subscribeToBooths(any, any))
          .thenReturn(mockChannel);

      final params1 = BoothsParams(eventId: 'event-1', teamId: testTeamId);
      final params2 = BoothsParams(eventId: 'event-2', teamId: testTeamId);

      container.read(boothsProvider(params1));
      container.read(boothsProvider(params2));

      await Future.delayed(Duration.zero);

      verify(mockBoothService.getBooths(eventId: 'event-1', teamId: testTeamId))
          .called(1);
      verify(mockBoothService.getBooths(eventId: 'event-2', teamId: testTeamId))
          .called(1);

      container.dispose();
    });

    test('boothProvider根据ID获取单个摊位', () async {
      final container = ProviderContainer(
        overrides: [
          boothServiceProvider.overrideWithValue(mockBoothService),
        ],
      );

      when(mockBoothService.getBooth(testBoothId))
          .thenAnswer((_) async => testBooth);

      final boothAsync = container.read(boothProvider(testBoothId));

      expect(boothAsync, isA<AsyncLoading>());

      await Future.delayed(Duration.zero);

      final booth = await container.read(boothProvider(testBoothId).future);

      expect(booth, isNotNull);
      expect(booth?.id, testBoothId);
      expect(booth?.boothNumber, 'B01');

      verify(mockBoothService.getBooth(testBoothId)).called(greaterThanOrEqualTo(1));

      container.dispose();
    });
  });
}
