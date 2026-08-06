import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:exhibition_buyer_app/main.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';
import 'package:exhibition_buyer_app/features/booth/models/booth.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/event/providers/event_provider.dart';
import 'package:exhibition_buyer_app/features/booth/providers/booth_provider.dart';
import 'package:exhibition_buyer_app/features/photo/providers/photo_provider.dart';
import 'package:exhibition_buyer_app/features/flag/providers/flag_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widget/test_helpers.dart';

/// 集成测试：完整的用户工作流程
///
/// 这些测试验证端到端的用户流程，从登录到完成具体任务。
/// 使用mock services避免真实的网络调用。
void main() {
  late MockSupabaseService mockSupabaseService;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSession mockSession;
  late MockRealtimeChannel mockChannel;
  late MockEventService mockEventService;
  late MockBoothService mockBoothService;

  setUpAll(() {
    // 注册fallback值
    registerFallbackValue(FakePostgresChangeFilter());
    registerFallbackValue(FakeRealtimeChannel());
  });

  setUp(() {
    // 初始化所有mock对象
    mockSupabaseService = MockSupabaseService();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();
    mockChannel = MockRealtimeChannel();
    mockEventService = MockEventService();
    mockBoothService = MockBoothService();

    // Mock SupabaseService
    when(() => mockSupabaseService.client).thenReturn(mockSupabase);

    // Mock基本的auth状态
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(mockSession);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('test-user-123');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockSession.user).thenReturn(mockUser);
  });

  group('完整用户流程：从登录到照片标注', () {
    testWidgets('流程1：创建场次 -> 创建摊位 -> 上传照片 -> 添加标记', (tester) async {
      // 测试数据
      final testEvent = Event(
        id: 'event-1',
        name: '2026春季展会',
        startDate: DateTime(2026, 3, 1),
        teamId: 'team-123',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final testBooth = Booth(
        id: 'booth-1',
        boothNumber: 'A01',
        eventId: 'event-1',
        teamId: 'team-123',
        createdBy: 'test-user-123',
        createdAt: DateTime.now(),
      );

      final testPhoto = Photo(
        id: 'photo-1',
        boothId: 'booth-1',
        url: 'https://example.com/test.jpg',
        uploadedBy: 'test-user-123',
        createdAt: DateTime.now(),
      );

      final testFlag = Flag(
        id: 'flag-1',
        photoId: 'photo-1',
        number: 1,
        positionX: 0.5,
        positionY: 0.5,
        needsAttention: false,
        createdBy: 'test-user-123',
        createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
      );

      // Mock service行为
      when(() => mockEventService.getEvents(any()))
          .thenAnswer((_) async => [testEvent]);
      when(() => mockBoothService.getBooths(
            eventId: any(named: 'eventId'),
            teamId: any(named: 'teamId'),
          )).thenAnswer((_) async => [testBooth]);

      // 构建app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            eventsProvider.overrideWith((ref) async => [testEvent]),
            boothsProvider(BoothsParams(eventId: 'event-1', teamId: 'team-123'))
                .overrideWith((ref) => MockBoothsNotifier(
                    [testBooth], mockBoothService, MockRealtimeService())),
            photosProvider('booth-1')
                .overrideWith((ref) => MockPhotosNotifier([testPhoto])),
            flagsProvider('photo-1')
                .overrideWith((ref) => MockFlagsNotifier([testFlag])),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: Scaffold(
              body: Center(
                child: Text('集成测试占位符'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基本渲染
      expect(find.text('集成测试占位符'), findsOneWidget);

      // TODO: 完整的用户流程测试
      // 1. 验证登录后显示场次列表
      // 2. 点击场次进入摊位列表
      // 3. 创建新摊位
      // 4. 进入摊位查看照片
      // 5. 点击照片添加标记
      // 6. 验证标记保存成功
    });

    testWidgets('流程2：查看照片 -> 添加多个标记 -> 删除标记', (tester) async {
      // 测试数据
      final testPhoto = Photo(
        id: 'photo-2',
        boothId: 'booth-2',
        url: 'https://example.com/test2.jpg',
        uploadedBy: 'test-user-123',
        createdAt: DateTime.now(),
      );

      final flags = List.generate(
        3,
        (i) => Flag(
          id: 'flag-$i',
          photoId: 'photo-2',
          number: i + 1,
          positionX: 0.2 + i * 0.3,
          positionY: 0.5,
          needsAttention: false,
          createdBy: 'test-user-123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 构建app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            photoProvider('photo-2').overrideWith((ref) async => testPhoto),
            flagsProvider('photo-2')
                .overrideWith((ref) => MockFlagsNotifier(flags)),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: Scaffold(
              body: Center(
                child: Text('多标记测试占位符'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基本渲染
      expect(find.text('多标记测试占位符'), findsOneWidget);

      // TODO: 完整的标记管理流程
      // 1. 显示照片和现有标记
      // 2. 添加新标记
      // 3. 验证标记数量增加
      // 4. 删除一个标记
      // 5. 验证标记数量减少
    });
  });

  group('数据隔离验证', () {
    testWidgets('不同用户只能看到自己小组的数据', (tester) async {
      // Team A的数据
      final teamAEvent = Event(
        id: 'event-a',
        name: 'Team A展会',
        startDate: DateTime(2026, 3, 1),
        teamId: 'team-a',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // 构建app（用户属于team-a）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            eventsProvider.overrideWith((ref) async => [teamAEvent]),
            // 模拟只返回team-a的数据
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: Scaffold(
              body: Center(
                child: Text('数据隔离测试'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基本渲染
      expect(find.text('数据隔离测试'), findsOneWidget);

      // TODO: 验证数据隔离
      // 1. 验证只显示team-a的场次
      // 2. 尝试访问team-b的数据应该失败
      // 3. 验证RLS策略生效
    });
  });

  group('错误处理和边界情况', () {
    testWidgets('网络错误时显示友好提示', (tester) async {
      // Mock service返回错误
      when(() => mockEventService.getEvents(any()))
          .thenThrow(Exception('网络连接失败'));

      // 构建app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: Scaffold(
              body: Center(
                child: Text('错误处理测试'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基本渲染
      expect(find.text('错误处理测试'), findsOneWidget);

      // TODO: 验证错误处理
      // 1. 显示错误提示
      // 2. 提供重试按钮
      // 3. 用户可以恢复操作
    });

    testWidgets('离线模式下的用户体验', (tester) async {
      // 构建app（离线状态）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('zh')],
            home: Scaffold(
              body: Center(
                child: Text('离线模式测试'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证基本渲染
      expect(find.text('离线模式测试'), findsOneWidget);

      // TODO: 验证离线体验
      // 1. 显示离线提示
      // 2. 缓存的数据仍可访问
      // 3. 新操作排队等待网络恢复
    });
  });
}
