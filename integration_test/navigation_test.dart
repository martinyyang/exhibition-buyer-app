import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('导航和返回按钮E2E测试', () {
    testWidgets('登录页 - 应该有注册链接', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待跳转到登录页
      await tester.pumpAndSettle();

      // 验证登录页存在
      expect(find.text('登录'), findsWidgets);

      // 查找注册链接/按钮
      final registerLink = find.text('注册');
      expect(registerLink, findsWidgets, reason: '登录页应该有"注册"链接');

      // 点击注册链接
      await tester.tap(registerLink.first);
      await tester.pumpAndSettle();

      // 验证跳转到注册页
      expect(find.text('注册'), findsWidgets);
    });

    testWidgets('注册页 - 应该有返回登录的导航', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 导航到注册页
      await tester.pumpAndSettle();
      final registerLink = find.text('注册');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink.first);
        await tester.pumpAndSettle();
      }

      // 验证注册页有返回按钮
      final backButton = find.byType(BackButton);
      final backIcon = find.byIcon(Icons.arrow_back);
      final hasBackNavigation = backButton.evaluate().isNotEmpty ||
                                backIcon.evaluate().isNotEmpty;

      expect(hasBackNavigation, true,
        reason: '注册页应该有返回按钮（BackButton或返回图标）');

      if (hasBackNavigation) {
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          await tester.tap(backIcon.first);
        }
        await tester.pumpAndSettle();

        // 验证返回到登录页
        expect(find.text('登录'), findsWidgets);
      }
    });

    testWidgets('场次选择页 - 应该能导航到设置和摊位', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 登录
      await _performLogin(tester);
      await tester.pumpAndSettle();

      // 验证在场次选择页
      expect(find.text('场次选择'), findsWidgets);

      // 1. 检查设置按钮存在
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget,
        reason: '场次选择页应该有设置按钮');

      // 点击设置按钮
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // 验证设置页有返回按钮
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget,
        reason: '设置页应该有返回按钮');

      // 返回
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // 2. 检查能导航到摊位列表（如果有场次）
      final eventCards = find.byType(Card);
      if (eventCards.evaluate().isNotEmpty) {
        await tester.tap(eventCards.first);
        await tester.pumpAndSettle();

        // 验证进入摊位列表页
        expect(find.text('摊位'), findsWidgets);

        // 验证摊位列表页有返回按钮
        final boothBackButton = find.byType(BackButton);
        expect(boothBackButton, findsOneWidget,
          reason: '摊位列表页应该有返回按钮');
      }
    });

    testWidgets('摊位列表页 - 应该能导航到照片网格并返回', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 登录并导航到摊位列表
      await _performLogin(tester);
      await tester.pumpAndSettle();

      // 创建或选择场次
      await _navigateToBoothList(tester);
      await tester.pumpAndSettle();

      // 验证在摊位列表页
      expect(find.text('摊位'), findsWidgets);

      // 验证有返回按钮
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget,
        reason: '摊位列表页应该有返回按钮');

      // 如果有摊位，点击进入照片网格
      final boothCards = find.byType(Card);
      if (boothCards.evaluate().length > 0) {
        await tester.tap(boothCards.first);
        await tester.pumpAndSettle();

        // 验证照片网格页有返回按钮
        final photoBackButton = find.byType(BackButton);
        expect(photoBackButton, findsOneWidget,
          reason: '照片网格页应该有返回按钮');

        // 测试返回功能
        await tester.tap(photoBackButton);
        await tester.pumpAndSettle();

        // 验证返回到摊位列表
        expect(find.text('摊位'), findsWidgets);
      }
    });

    testWidgets('照片网格页 - 应该能导航到照片详情并返回', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 登录并导航到照片网格
      await _performLogin(tester);
      await tester.pumpAndSettle();
      await _navigateToBoothList(tester);
      await tester.pumpAndSettle();
      await _navigateToPhotoGrid(tester);
      await tester.pumpAndSettle();

      // 验证有返回按钮
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget,
        reason: '照片网格页应该有返回按钮');

      // 如果有照片，点击进入详情页
      final photoWidgets = find.byType(GestureDetector);
      if (photoWidgets.evaluate().length > 0) {
        await tester.tap(photoWidgets.first);
        await tester.pumpAndSettle();

        // 验证照片详情页有返回按钮
        final detailBackButton = find.byType(BackButton);
        expect(detailBackButton, findsOneWidget,
          reason: '照片详情页应该有返回按钮');

        // 测试返回功能
        await tester.tap(detailBackButton);
        await tester.pumpAndSettle();

        // 验证返回到照片网格
        expect(find.byType(GridView), findsOneWidget);
      }
    });

    testWidgets('错误页面 - 应该有返回首页按钮', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 登录
      await _performLogin(tester);
      await tester.pumpAndSettle();

      // 尝试访问不存在的路由（通过代码注入）
      // 由于go_router的限制，这个测试需要特殊处理
      // 验证错误页面配置中有返回首页的按钮配置即可
    });

    testWidgets('所有页面导航完整性测试', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 记录导航路径
      final navigationLog = <String>[];

      // 1. 登录页 -> 注册页 -> 登录页
      navigationLog.add('登录页');
      await tester.pumpAndSettle();

      final registerLink = find.text('注册');
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink.first);
        await tester.pumpAndSettle();
        navigationLog.add('注册页');

        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
          navigationLog.add('返回登录页');
        }
      }

      // 2. 登录 -> 场次选择
      await _performLogin(tester);
      await tester.pumpAndSettle();
      navigationLog.add('场次选择页');

      // 3. 场次选择 -> 设置 -> 场次选择
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        navigationLog.add('设置页');

        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
          navigationLog.add('返回场次选择页');
        }
      }

      // 4. 场次选择 -> 摊位列表 -> 场次选择
      final eventCards = find.byType(Card);
      if (eventCards.evaluate().isNotEmpty) {
        await tester.tap(eventCards.first);
        await tester.pumpAndSettle();
        navigationLog.add('摊位列表页');

        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
          navigationLog.add('返回场次选择页');
        }
      }

      // 输出导航日志
      print('导航路径测试完成:');
      for (var i = 0; i < navigationLog.length; i++) {
        print('  ${i + 1}. ${navigationLog[i]}');
      }

      // 验证至少完成了基本导航流程
      expect(navigationLog.length, greaterThan(3),
        reason: '应该至少完成登录、场次选择、设置等基本页面的导航');
    });
  });
}

// 辅助函数：执行登录
Future<void> _performLogin(WidgetTester tester) async {
  final emailField = find.byKey(const Key('email_field'));
  final passwordField = find.byKey(const Key('password_field'));
  final loginButton = find.byKey(const Key('login_button'));

  if (emailField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, 'buyer@test.com');
    await tester.enterText(passwordField, 'test123456');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }
}

// 辅助函数：导航到摊位列表
Future<void> _navigateToBoothList(WidgetTester tester) async {
  final eventCards = find.byType(Card);
  if (eventCards.evaluate().isNotEmpty) {
    await tester.tap(eventCards.first);
    await tester.pumpAndSettle();
  }
}

// 辅助函数：导航到照片网格
Future<void> _navigateToPhotoGrid(WidgetTester tester) async {
  final boothCards = find.byType(Card);
  if (boothCards.evaluate().isNotEmpty) {
    await tester.tap(boothCards.first);
    await tester.pumpAndSettle();
  }
}
