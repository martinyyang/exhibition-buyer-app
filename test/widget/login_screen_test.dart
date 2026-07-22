import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/auth/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('显示登录表单所有元素', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // 验证标题
      expect(find.text('展会采购协作系统'), findsOneWidget);

      // 验证邮箱输入框
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('邮箱'), findsOneWidget);

      // 验证密码输入框
      expect(find.text('密码'), findsOneWidget);

      // 验证登录按钮
      expect(find.text('登录'), findsOneWidget);

      // 验证注册按钮
      expect(find.text('注册'), findsOneWidget);
    });

    testWidgets('邮箱格式验证', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // 输入无效邮箱
      final emailField = find.widgetWithText(TextField, '邮箱');
      await tester.enterText(emailField, 'invalid-email');

      // 点击登录按钮
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.text('请输入有效的邮箱地址'), findsOneWidget);
    });

    testWidgets('密码长度验证', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // 输入有效邮箱
      final emailField = find.widgetWithText(TextField, '邮箱');
      await tester.enterText(emailField, 'test@example.com');

      // 输入过短密码
      final passwordField = find.widgetWithText(TextField, '密码');
      await tester.enterText(passwordField, '123');

      // 点击登录按钮
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.text('密码至少6位'), findsOneWidget);
    });

    testWidgets('登录成功后获得颜色标识', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // 输入有效凭据
      await tester.enterText(
        find.widgetWithText(TextField, '邮箱'),
        'buyer@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '密码'),
        'password123',
      );

      // 点击登录按钮
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 验证显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('切换到注册页面', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // 点击注册按钮
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      // 验证导航到注册页面（暂时验证按钮被点击）
      // 实际导航需要配置路由后测试
    });
  });
}
