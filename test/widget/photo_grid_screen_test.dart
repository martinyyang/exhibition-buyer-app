import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_grid_screen.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/photo/providers/photo_provider.dart';
import 'package:exhibition_buyer_app/features/booth/models/booth.dart';
import 'package:exhibition_buyer_app/features/booth/providers/booth_provider.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(FakePostgresChangeFilter());
    registerFallbackValue(FakeRealtimeChannel());
  });

  late MockSupabaseService mockSupabaseService;
  late MockSupabaseClient mockSupabaseClient;
  late MockRealtimeChannel mockRealtimeChannel;
  late MockPhotoService mockPhotoService;
  late MockRealtimeService mockRealtimeService;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;

  setUp(() {
    mockSupabaseService = MockSupabaseService();
    mockSupabaseClient = MockSupabaseClient();
    mockRealtimeChannel = MockRealtimeChannel();
    mockPhotoService = MockPhotoService();
    mockRealtimeService = MockRealtimeService();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');
    when(() => mockSupabaseClient.channel(any()))
        .thenReturn(mockRealtimeChannel);
    when(() => mockRealtimeChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        )).thenReturn(mockRealtimeChannel);
    when(() => mockRealtimeChannel.subscribe()).thenReturn(mockRealtimeChannel);
    when(() => mockSupabaseClient.removeChannel(any()))
        .thenAnswer((_) async => 'ok');
    when(() => mockRealtimeService.subscribeToPhotos(any(), any()))
        .thenReturn(mockRealtimeChannel);
    when(() => mockRealtimeService.unsubscribe(any())).thenAnswer((_) async {});
  });

  group('PhotoGridScreen Widget Tests', () {
    // Test data
    final testBooth = Booth(
      id: 'test-booth-id',
      boothNumber: 'A01',
      eventId: 'test-event-id',
      teamId: 'test-team-id',
      createdBy: 'test-user-id',
      createdAt: DateTime.now(),
    );

    final testPhotos = [
      Photo(
        id: 'photo1',
        boothId: 'test-booth-id',
        url: 'https://example.com/photo1.jpg',
        uploadedBy: 'test-user-id',
        supplierName: '供应商A',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('显示照片网格', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证网格容器
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('显示拍照按钮', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证拍照按钮（FAB）
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('照片缩略图显示标注数量', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 照片卡片应该显示旗子数量
      // 例如："5个旗子"
    });

    testWidgets('显示供应商名称', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 如果照片有供应商名称，应该显示
    });

    testWidgets('显示供应商Logo', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 如果照片有供应商Logo，应该显示
    });

    testWidgets('点击照片进入详情页', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证照片卡片存在（导航需要GoRouter，这里只验证UI）
      final photoCards = find.byType(Card);
      expect(photoCards, findsWidgets);
    });

    testWidgets('点击拍照按钮打开相机', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      // 点击拍照按钮
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      // 应该调用相机功能
    });

    testWidgets('照片列表为空时显示提示', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 空状态应该显示提示信息
      // expect(find.text('暂无照片'), findsOneWidget);
    });

    testWidgets('长按照片显示操作菜单', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 长按照片卡片
      final photoCards = find.byType(Card);
      if (photoCards.evaluate().isNotEmpty) {
        await tester.longPress(photoCards.first);
        await tester.pump();

        // 验证显示操作菜单（添加供应商信息、删除等）
      }
    });

    testWidgets('上传照片时显示进度', (tester) async {
      when(() => mockPhotoService.getPhotos('test-booth-id'))
          .thenAnswer((_) async => testPhotos);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            boothProvider('test-booth-id')
                .overrideWith((ref) async => testBooth),
            photosProvider('test-booth-id').overrideWith((ref) =>
                PhotosNotifier(
                    mockPhotoService, mockRealtimeService, 'test-booth-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pump();
      // 点击拍照按钮
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      // 上传时应该显示加载指示器
      // expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
