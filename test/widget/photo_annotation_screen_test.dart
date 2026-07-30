import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_annotation_screen.dart';
import 'package:exhibition_buyer_app/features/photo/providers/photo_provider.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/auth/models/user.dart'
    as app_user;
import 'package:exhibition_buyer_app/features/flag/providers/flag_provider.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';
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

  setUp(() {
    mockSupabaseService = MockSupabaseService();
    mockSupabaseClient = MockSupabaseClient();
    mockRealtimeChannel = MockRealtimeChannel();

    when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);

    // Configure RealtimeChannel mock
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
  });

  group('PhotoAnnotationScreen Widget Tests', () {
    final testUser = app_user.User(
      id: 'user1',
      email: 'test@test.com',
      role: 'buyer',
      teamId: 'team1',
      createdAt: DateTime.now(),
    );

    final testPhoto = Photo(
      id: 'photo1',
      createdAt: DateTime.now(),
      boothId: 'booth1',
      url: 'https://example.com/photo.jpg',
      uploadedBy: 'user1',
    );

    final testFlags = [
      Flag(
        id: 'flag1',
        createdAt: DateTime.now(),
        photoId: 'photo1',
        number: 1,
        positionX: 0.3,
        positionY: 0.3,
        priceRmb: 100.0,
        needsAttention: false,
        createdBy: 'user1',
      ),
    ];

    testWidgets('显示照片标注界面', (tester) async {
      final mockFlagService = MockFlagService();
      when(() => mockFlagService.getFlags('photo1'))
          .thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoProvider('photo1')
                .overrideWith((ref) => Future.value(testPhoto)),
            flagServiceProvider.overrideWithValue(mockFlagService),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(testUser)),
          ],
          child: const MaterialApp(
            home: PhotoAnnotationScreen(photoId: 'photo1'),
          ),
        ),
      );

      await tester.pump();

      // 验证标题
      expect(find.text('照片标注'), findsOneWidget);

      // 验证添加标记按钮
      expect(find.byIcon(Icons.add_location), findsOneWidget);
    });

    testWidgets('切换到添加模式', (tester) async {
      final mockFlagService = MockFlagService();
      when(() => mockFlagService.getFlags('photo1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoProvider('photo1')
                .overrideWith((ref) => Future.value(testPhoto)),
            flagServiceProvider.overrideWithValue(mockFlagService),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(testUser)),
          ],
          child: const MaterialApp(
            home: PhotoAnnotationScreen(photoId: 'photo1'),
          ),
        ),
      );

      await tester.pump();

      // 点击添加标记按钮
      await tester.tap(find.byIcon(Icons.add_location));
      await tester.pump();

      // 验证提示信息显示
      expect(find.text('点击照片任意位置添加标记'), findsOneWidget);

      // 验证图标变为完成
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('照片不存在时显示提示', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoProvider('photo1').overrideWith((ref) => Future.value(null)),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(testUser)),
          ],
          child: const MaterialApp(
            home: PhotoAnnotationScreen(photoId: 'photo1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证提示信息
      expect(find.text('照片不存在'), findsOneWidget);
    });
  });
}
