import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/formula/screens/formula_management_screen.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/auth/models/user.dart'
    as app_user;
import 'package:exhibition_buyer_app/features/formula/providers/formula_provider.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';
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

  group('FormulaManagementScreen Widget Tests', () {
    final testUser = app_user.User(
      id: 'user1',
      email: 'test@test.com',
      role: 'buyer',
      teamId: 'team1',
      createdAt: DateTime.now(),
    );

    testWidgets('显示标题和帮助按钮', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(testUser)),
            currentFormulaProvider('team1').overrideWith(
              (ref) => CurrentFormulaNotifier(
                ref.watch(exchangeSettingsServiceProvider),
                ref.watch(realtimeServiceProvider),
                'team1',
              )..state = const AsyncValue.data('{{price}} * 7.2'),
            ),
            formulaHistoryProvider('team1').overrideWith(
              (ref) => FormulaHistoryNotifier(
                ref.watch(formulaHistoryServiceProvider),
                ref.watch(realtimeServiceProvider),
                'team1',
              )..state = const AsyncValue.data([]),
            ),
          ],
          child: const MaterialApp(
            home: FormulaManagementScreen(),
          ),
        ),
      );

      await tester.pump();

      // 验证标题
      expect(find.text('汇率公式管理'), findsOneWidget);

      // 验证帮助按钮存在
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('未登录时显示提示', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            currentUserDataProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: FormulaManagementScreen(),
          ),
        ),
      );

      await tester.pump();

      // 验证提示信息
      expect(find.text('未找到团队信息'), findsOneWidget);
    });

    testWidgets('显示公式输入区域', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseServiceProvider.overrideWithValue(mockSupabaseService),
            currentUserDataProvider
                .overrideWith((ref) => Future.value(testUser)),
            currentFormulaProvider('team1').overrideWith(
              (ref) => CurrentFormulaNotifier(
                ref.watch(exchangeSettingsServiceProvider),
                ref.watch(realtimeServiceProvider),
                'team1',
              )..state = const AsyncValue.data('{{price}} * 7.2'),
            ),
            formulaHistoryProvider('team1').overrideWith(
              (ref) => FormulaHistoryNotifier(
                ref.watch(formulaHistoryServiceProvider),
                ref.watch(realtimeServiceProvider),
                'team1',
              )..state = const AsyncValue.data([]),
            ),
          ],
          child: const MaterialApp(
            home: FormulaManagementScreen(),
          ),
        ),
      );

      await tester.pump();

      // 验证公式输入区域标题
      expect(find.text('设置新公式'), findsOneWidget);
    });
  });
}
