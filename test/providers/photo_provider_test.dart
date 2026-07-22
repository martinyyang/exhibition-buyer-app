import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:展会专用APP/features/photo/providers/photo_provider.dart';
import 'package:展会专用APP/features/photo/services/photo_service.dart';
import 'package:展会专用APP/features/photo/models/photo.dart';
import 'package:展会专用APP/core/services/realtime_service.dart';

// Mock classes
class MockPhotoService extends Mock implements PhotoService {}
class MockRealtimeService extends Mock implements RealtimeService {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  late MockPhotoService mockPhotoService;
  late MockRealtimeService mockRealtimeService;
  late MockRealtimeChannel mockChannel;

  setUp(() {
    mockPhotoService = MockPhotoService();
    mockRealtimeService = MockRealtimeService();
    mockChannel = MockRealtimeChannel();
  });

  group('PhotoProvider - Provider集成测试', () {
    const testBoothId = 'booth-123';
    const testUserId = 'user-456';

    final testPhotos = [
      Photo(
        id: 'photo-1',
        createdAt: DateTime.now(),
        boothId: testBoothId,
        url: 'https://example.com/photo1.jpg',
        uploadedBy: testUserId,
      ),
      Photo(
        id: 'photo-2',
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        boothId: testBoothId,
        url: 'https://example.com/photo2.jpg',
        uploadedBy: testUserId,
        supplierName: 'Test Supplier',
      ),
    ];

    test('Provider Family按boothId正确过滤照片', () async {
      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => testPhotos);
      when(() => mockRealtimeService.subscribeToPhotos(any(), any()))
          .thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(photosProvider(testBoothId).future);

      final photosState = container.read(photosProvider(testBoothId));

      expect(photosState.hasValue, isTrue);
      expect(photosState.value, hasLength(2));
      expect(photosState.value!.every((p) => p.boothId == testBoothId), isTrue);

      verify(() => mockPhotoService.getPhotos(testBoothId)).called(1);
    });

    test('不同boothId创建不同的Provider实例', () async {
      const booth1Id = 'booth-1';
      const booth2Id = 'booth-2';

      final booth1Photos = [
        Photo(
          id: 'photo-booth1',
          createdAt: DateTime.now(),
          boothId: booth1Id,
          url: 'https://example.com/photo1.jpg',
          uploadedBy: testUserId,
        ),
      ];

      final booth2Photos = [
        Photo(
          id: 'photo-booth2',
          createdAt: DateTime.now(),
          boothId: booth2Id,
          url: 'https://example.com/photo2.jpg',
          uploadedBy: testUserId,
        ),
      ];

      when(() => mockPhotoService.getPhotos(booth1Id))
          .thenAnswer((_) async => booth1Photos);
      when(() => mockPhotoService.getPhotos(booth2Id))
          .thenAnswer((_) async => booth2Photos);
      when(() => mockRealtimeService.subscribeToPhotos(any(), any()))
          .thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );
      addTearDown(container.dispose);

      // Load both providers
      await container.read(photosProvider(booth1Id).future);
      await container.read(photosProvider(booth2Id).future);

      final booth1State = container.read(photosProvider(booth1Id));
      final booth2State = container.read(photosProvider(booth2Id));

      expect(booth1State.value, hasLength(1));
      expect(booth1State.value![0].boothId, booth1Id);

      expect(booth2State.value, hasLength(1));
      expect(booth2State.value![0].boothId, booth2Id);

      // Verify separate calls
      verify(() => mockPhotoService.getPhotos(booth1Id)).called(1);
      verify(() => mockPhotoService.getPhotos(booth2Id)).called(1);
    });

    test('初始化时订阅Realtime更新', () async {
      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => testPhotos);
      when(() => mockRealtimeService.subscribeToPhotos(testBoothId, any()))
          .thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(photosProvider(testBoothId).future);

      // Verify subscription was created
      verify(() => mockRealtimeService.subscribeToPhotos(
        testBoothId,
        any(),
      )).called(1);
    });

    test('Realtime更新时自动刷新照片列表', () async {
      Function(dynamic)? realtimeCallback;

      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => testPhotos);
      when(() => mockRealtimeService.subscribeToPhotos(testBoothId, any()))
          .thenAnswer((invocation) {
        realtimeCallback = invocation.positionalArguments[1] as Function(dynamic);
        return mockChannel;
      });

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );
      addTearDown(container.dispose);

      // Initial load
      await container.read(photosProvider(testBoothId).future);
      verify(() => mockPhotoService.getPhotos(testBoothId)).called(1);

      // Simulate realtime update
      final updatedPhotos = [
        ...testPhotos,
        Photo(
          id: 'photo-3',
          createdAt: DateTime.now(),
          boothId: testBoothId,
          url: 'https://example.com/photo3.jpg',
          uploadedBy: testUserId,
        ),
      ];

      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => updatedPhotos);

      // Trigger realtime callback
      realtimeCallback!({'event': 'INSERT'});

      // Wait for refresh
      await Future.delayed(Duration(milliseconds: 100));
      await container.read(photosProvider(testBoothId).future);

      final state = container.read(photosProvider(testBoothId));
      expect(state.value, hasLength(3));

      // Verify refresh was called
      verify(() => mockPhotoService.getPhotos(testBoothId)).called(greaterThanOrEqualTo(2));
    });

    test('Provider dispose时取消Realtime订阅', () async {
      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => testPhotos);
      when(() => mockRealtimeService.subscribeToPhotos(testBoothId, any()))
          .thenReturn(mockChannel);
      when(() => mockRealtimeService.unsubscribe(mockChannel))
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );

      await container.read(photosProvider(testBoothId).future);

      // Dispose container
      container.dispose();

      // Verify unsubscribe was called
      verify(() => mockRealtimeService.unsubscribe(mockChannel)).called(1);
    });

    test('加载失败时Provider返回错误状态', () async {
      final error = Exception('Failed to load photos');

      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenThrow(error);
      when(() => mockRealtimeService.subscribeToPhotos(testBoothId, any()))
          .thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for error
      await Future.delayed(Duration(milliseconds: 100));

      final state = container.read(photosProvider(testBoothId));

      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Failed to load photos'));
    });

    test('refresh方法手动刷新照片列表', () async {
      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => testPhotos);
      when(() => mockRealtimeService.subscribeToPhotos(testBoothId, any()))
          .thenReturn(mockChannel);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
          realtimeServiceProvider.overrideWithValue(mockRealtimeService),
        ],
      );
      addTearDown(container.dispose);

      // Initial load
      await container.read(photosProvider(testBoothId).future);
      verify(() => mockPhotoService.getPhotos(testBoothId)).called(1);

      // Update mock data
      final updatedPhotos = [
        testPhotos[0].copyWith(supplierName: 'Updated Supplier'),
      ];
      when(() => mockPhotoService.getPhotos(testBoothId))
          .thenAnswer((_) async => updatedPhotos);

      // Manual refresh
      await container.read(photosProvider(testBoothId).notifier).refresh();

      final state = container.read(photosProvider(testBoothId));
      expect(state.value, hasLength(1));
      expect(state.value![0].supplierName, 'Updated Supplier');

      verify(() => mockPhotoService.getPhotos(testBoothId)).called(greaterThanOrEqualTo(2));
    });

    test('photoProvider返回单个照片', () async {
      const photoId = 'photo-123';
      final photo = Photo(
        id: photoId,
        createdAt: DateTime.now(),
        boothId: testBoothId,
        url: 'https://example.com/photo.jpg',
        uploadedBy: testUserId,
      );

      when(() => mockPhotoService.getPhoto(photoId))
          .thenAnswer((_) async => photo);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(photoProvider(photoId).future);

      expect(result, isNotNull);
      expect(result!.id, photoId);

      verify(() => mockPhotoService.getPhoto(photoId)).called(1);
    });

    test('photoProvider照片不存在时返回null', () async {
      const photoId = 'non-existent';

      when(() => mockPhotoService.getPhoto(photoId))
          .thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          photoServiceProvider.overrideWithValue(mockPhotoService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(photoProvider(photoId).future);

      expect(result, isNull);
    });
  });
}
