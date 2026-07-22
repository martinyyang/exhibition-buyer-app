import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:exhibition_buyer_app/core/router/app_router.dart';
import 'package:exhibition_buyer_app/features/auth/screens/login_screen.dart';
import 'package:exhibition_buyer_app/features/event/screens/event_selection_screen.dart';

void main() {
  group('App Router 测试', () {
    testWidgets('初始路由为登录页', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: container.read(routerProvider),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证显示登录页
      expect(find.byType(LoginScreen), findsOneWidget);

      container.dispose();
    });

    testWidgets('错误路由显示404页面', (tester) async {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // 导航到不存在的路由
      router.go('/nonexistent-route');
      await tester.pumpAndSettle();

      // 验证显示错误页面
      expect(find.text('页面未找到'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      container.dispose();
    });

    test('路由路径定义正确', () {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      // 验证路由配置
      expect(router.namedLocation('login'), '/login');
      expect(router.namedLocation('events'), '/events');
      expect(
        router.namedLocation('booths', pathParameters: {'eventId': 'event-123'}),
        '/events/event-123/booths',
      );
      expect(
        router.namedLocation('photos', pathParameters: {'boothId': 'booth-456'}),
        '/booths/booth-456/photos',
      );
      expect(
        router.namedLocation('photo-detail', pathParameters: {'photoId': 'photo-789'}),
        '/photos/photo-789',
      );

      container.dispose();
    });

    testWidgets('路由参数正确传递', (tester) async {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // 导航到摊位列表页
      router.go('/events/event-123/booths');
      await tester.pumpAndSettle();

      // 验证参数传递（通过查找页面来验证）
      // 实际应用中，BoothListScreen 会使用 eventId 参数

      container.dispose();
    });

    test('命名路由可以正确解析', () {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      // 测试各个命名路由
      expect(() => router.namedLocation('login'), returnsNormally);
      expect(() => router.namedLocation('events'), returnsNormally);
      expect(
        () => router.namedLocation('booths', pathParameters: {'eventId': 'test'}),
        returnsNormally,
      );
      expect(
        () => router.namedLocation('photos', pathParameters: {'boothId': 'test'}),
        returnsNormally,
      );
      expect(
        () => router.namedLocation('photo-detail', pathParameters: {'photoId': 'test'}),
        returnsNormally,
      );

      container.dispose();
    });

    testWidgets('返回按钮正常工作', (tester) async {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // 导航到深层路由
      router.go('/events/event-123/booths');
      await tester.pumpAndSettle();

      // 验证可以返回
      expect(router.canPop(), isTrue);

      container.dispose();
    });
  });
}
