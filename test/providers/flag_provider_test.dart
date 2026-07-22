import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/flag/providers/flag_provider.dart';
import 'package:exhibition_buyer_app/features/flag/services/flag_service.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';

@GenerateMocks([FlagService, RealtimeService, RealtimeChannel])
import 'flag_provider_test.mocks.dart';

void main() {
  late MockFlagService mockFlagService;
  late MockRealtimeService mockRealtimeService;
  late MockRealtimeChannel mockChannel;

  setUp(() {
    mockFlagService = MockFlagService();
    mockRealtimeService = MockRealtimeService();
    mockChannel = MockRealtimeChannel();
  });

  group('FlagProvider - Provider Family', () {
    test('不同photoId返回不同的Provider实例', () async {
      final photoId1 = 'photo-111';
      final photoId2 = 'photo-222';

      // Mock返回不同照片的旗子
      when(mockFlagService.getFlags(photoId1)).thenAnswer((_) async => [
            Flag(
              id: 'flag-1',
              createdAt: DateTime.now(),
              photoId: photoId1,
              number: 1,
              positionX: 0.5,
              positionY: 0.5,
              needsAttention: false,
              createdBy: 'user-123',
            ),
          ]);

      when(mockFlagService.getFlags(photoId2)).thenAnswer((_) async => [
            Flag(
              id: 'flag-2',
              createdAt: DateTime.now(),
              photoId: photoId2,
              number: 1,
              positionX: 0.3,
              positionY: 0.7,
              needsAttention: false,
              createdBy: 'user-123',
            ),
          ]);

      when(mockRealtimeService.subscribeToFlags(any, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      // 获取两个不同照片的旗子列表
      final flags1Future = container.read(flagsProvider(photoId1).future);
      final flags2Future = container.read(flagsProvider(photoId2).future);

      final flags1 = await flags1Future;
      final flags2 = await flags2Future;

      expect(flags1.length, 1);
      expect(flags1[0].photoId, photoId1);
      expect(flags2.length, 1);
      expect(flags2[0].photoId, photoId2);

      container.dispose();
    });

    test('同一photoId多次访问返回相同Provider实例', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFlags(any, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      // 多次读取同一photoId
      container.read(flagsProvider(photoId));
      container.read(flagsProvider(photoId));
      container.read(flagsProvider(photoId));

      // 应该只订阅一次
      verify(mockRealtimeService.subscribeToFlags(photoId, any)).called(1);

      container.dispose();
    });
  });

  group('FlagProvider - Realtime订阅', () {
    test('初始化时自动订阅Realtime更新', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      container.read(flagsProvider(photoId));

      // 等待初始化完成
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockRealtimeService.subscribeToFlags(photoId, any)).called(1);

      container.dispose();
    });

    test('Provider销毁时取消订阅', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);
      when(mockRealtimeService.unsubscribe(mockChannel)).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      container.read(flagsProvider(photoId));
      await Future.delayed(Duration(milliseconds: 100));

      // 销毁容器
      container.dispose();

      // 应该调用unsubscribe
      verify(mockRealtimeService.unsubscribe(mockChannel)).called(1);
    });

    test('Realtime数据变化时自动刷新', () async {
      final photoId = 'photo-123';
      late Function(dynamic) onUpdateCallback;

      // 初始数据
      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => [
            Flag(
              id: 'flag-1',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 1,
              positionX: 0.5,
              positionY: 0.5,
              needsAttention: false,
              createdBy: 'user-123',
            ),
          ]);

      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenAnswer((invocation) {
        onUpdateCallback = invocation.positionalArguments[1] as Function(dynamic);
        return mockChannel;
      });

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      final listener = MockListener<AsyncValue<List<Flag>>>();
      container.listen(flagsProvider(photoId), listener.call, fireImmediately: true);

      await Future.delayed(Duration(milliseconds: 100));

      // 模拟Realtime更新（新增一个旗子）
      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => [
            Flag(
              id: 'flag-1',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 1,
              positionX: 0.5,
              positionY: 0.5,
              needsAttention: false,
              createdBy: 'user-123',
            ),
            Flag(
              id: 'flag-2',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 2,
              positionX: 0.3,
              positionY: 0.7,
              needsAttention: false,
              createdBy: 'user-123',
            ),
          ]);

      onUpdateCallback({'event': 'INSERT'});

      await Future.delayed(Duration(milliseconds: 100));

      // 验证getFlags被调用了至少2次（初始化 + Realtime更新）
      verify(mockFlagService.getFlags(photoId)).called(greaterThanOrEqualTo(2));

      container.dispose();
    });
  });

  group('FlagProvider - 状态管理', () {
    test('初始状态为loading', () {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      final state = container.read(flagsProvider(photoId));

      expect(state, isA<AsyncLoading>());

      container.dispose();
    });

    test('加载成功后状态为data', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => [
            Flag(
              id: 'flag-1',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 1,
              positionX: 0.5,
              positionY: 0.5,
              needsAttention: false,
              createdBy: 'user-123',
            ),
          ]);

      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      final stateFuture = container.read(flagsProvider(photoId).future);
      final flags = await stateFuture;

      expect(flags.length, 1);
      expect(flags[0].id, 'flag-1');

      container.dispose();
    });

    test('加载失败后状态为error', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenThrow(Exception('网络错误'));
      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      await expectLater(
        container.read(flagsProvider(photoId).future),
        throwsException,
      );

      container.dispose();
    });
  });

  group('FlagProvider - 旗子排序', () {
    test('返回的旗子按编号升序排列', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => [
            Flag(
              id: 'flag-1',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 1,
              positionX: 0.5,
              positionY: 0.5,
              needsAttention: false,
              createdBy: 'user-123',
            ),
            Flag(
              id: 'flag-2',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 2,
              positionX: 0.3,
              positionY: 0.7,
              needsAttention: false,
              createdBy: 'user-123',
            ),
            Flag(
              id: 'flag-3',
              createdAt: DateTime.now(),
              photoId: photoId,
              number: 3,
              positionX: 0.8,
              positionY: 0.2,
              needsAttention: false,
              createdBy: 'user-123',
            ),
          ]);

      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      final flags = await container.read(flagsProvider(photoId).future);

      expect(flags[0].number, lessThan(flags[1].number));
      expect(flags[1].number, lessThan(flags[2].number));
      expect(flags[0].number, 1);
      expect(flags[1].number, 2);
      expect(flags[2].number, 3);

      container.dispose();
    });
  });

  group('FlagProvider - refresh方法', () {
    test('手动刷新重新加载数据', () async {
      final photoId = 'photo-123';

      when(mockFlagService.getFlags(photoId)).thenAnswer((_) async => []);
      when(mockRealtimeService.subscribeToFlags(photoId, any)).thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          flagServiceProvider.overrideWithValue(mockFlagService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      await container.read(flagsProvider(photoId).future);

      // 手动刷新
      await container.read(flagsProvider(photoId).notifier).refresh();

      // 验证getFlags被调用了2次（初始化 + 手动刷新）
      verify(mockFlagService.getFlags(photoId)).called(2);

      container.dispose();
    });
  });
}

class MockListener<T> extends Mock {
  void call(T? previous, T next);
}
