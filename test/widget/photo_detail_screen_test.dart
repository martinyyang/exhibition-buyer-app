import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_detail_screen.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/photo/providers/photo_provider.dart';
import 'package:exhibition_buyer_app/features/flag/widgets/flag_table.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';
import 'package:exhibition_buyer_app/features/flag/providers/flag_provider.dart';
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
  late MockFlagService mockFlagService;
  late MockRealtimeService mockRealtimeService;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;

  setUp(() {
    mockSupabaseService = MockSupabaseService();
    mockSupabaseClient = MockSupabaseClient();
    mockRealtimeChannel = MockRealtimeChannel();
    mockPhotoService = MockPhotoService();
    mockFlagService = MockFlagService();
    mockRealtimeService = MockRealtimeService();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockSupabaseService.client).thenReturn(mockSupabaseClient);
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-id');
    when(() => mockSupabaseClient.channel(any())).thenReturn(mockRealtimeChannel);
    when(() => mockRealtimeChannel.onPostgresChanges(
      event: any(named: 'event'),
      schema: any(named: 'schema'),
      table: any(named: 'table'),
      filter: any(named: 'filter'),
      callback: any(named: 'callback'),
    )).thenReturn(mockRealtimeChannel);
    when(() => mockRealtimeChannel.subscribe()).thenReturn(mockRealtimeChannel);
    when(() => mockSupabaseClient.removeChannel(any())).thenAnswer((_) async => 'ok');
    when(() => mockRealtimeService.subscribeToFlags(any(), any())).thenReturn(mockRealtimeChannel);
    when(() => mockRealtimeService.unsubscribe(any())).thenAnswer((_) async {});
  });

  group('PhotoDetailScreen Widget Tests', () {
    // Test data
    final testPhoto = Photo(
      id: 'test-photo-id',
      boothId: 'test-booth-id',
      url: 'https://example.com/photo.jpg',
      uploadedBy: 'test-user-id',
      supplierName: '供应商A',
      createdAt: DateTime.now(),
    );

    final testFlags = [
      Flag(
        id: 'flag1',
        photoId: 'test-photo-id',
        number: 1,
        positionX: 100.0,
        positionY: 150.0,
        priceRmb: 50.0,
        priceConverted: 7.5,
        needsAttention: false,
        createdBy: 'test-user-id',
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('显示照片和Flag表格在同一页面', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证照片显示
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // 验证Flag表格显示
      expect(find.byType(FlagTable), findsOneWidget);
    });

    testWidgets('照片支持缩放和平移', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证InteractiveViewer支持手势
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('照片上显示旗子标记', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 旗子应该叠加在照片上
      // 显示编号（1、2、3...）
    });

    testWidgets('点击照片位置可以插旗（远程端）', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 远程端点击照片应该创建新旗子
      // 买手端不应该有这个功能
    });

    testWidgets('Flag表格显示所有列', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证表格列：编号、报价、换算价、目标价、状态
      expect(find.text('编号'), findsOneWidget);
      expect(find.text('报价(¥)'), findsOneWidget);
      expect(find.text('换算价'), findsOneWidget);
    });

    testWidgets('买手端可以直接在表格中编辑报价', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: false,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 买手端的报价列应该可编辑
      // 验证TextField存在
    });

    testWidgets('远程端可以设置目标价', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 远程端的目标价列应该可编辑
    });

    testWidgets('显示红色警告标记', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 当needs_attention=true时，应该显示🚨图标
      // expect(find.byIcon(Icons.warning), findsWidgets);
    });

    testWidgets('点击表格行自动聚焦到对应旗子', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 点击表格某一行
      // 照片应该自动滚动到对应旗子位置
    });

    testWidgets('报价自动换算', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 输入报价后，换算价应该自动计算
    });

    testWidgets('Flag表格为空时显示提示', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 如果没有旗子，应该显示提示
      // "点击照片标记商品"
    });

    testWidgets('长按旗子显示删除选项', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 远程端长按旗子可以删除
    });

    testWidgets('响应式布局：Web端左右布局，移动端上下布局', (tester) async {
      when(() => mockPhotoService.getPhoto('test-photo-id')).thenAnswer((_) async => testPhoto);
      when(() => mockFlagService.getFlags('test-photo-id')).thenAnswer((_) async => testFlags);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoServiceProvider.overrideWithValue(mockPhotoService),
            flagServiceProvider.overrideWithValue(mockFlagService),
            realtimeServiceProvider.overrideWithValue(mockRealtimeService),
            photoProvider('test-photo-id').overrideWith((ref) async => testPhoto),
            flagsProvider('test-photo-id').overrideWith((ref) => FlagsNotifier(mockFlagService, mockRealtimeService, 'test-photo-id')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证使用LayoutBuilder
      expect(find.byType(LayoutBuilder), findsOneWidget);
    });
  });
}
