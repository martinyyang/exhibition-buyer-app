import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/auth/screens/register_screen.dart';

void main() {
  group('RegisterScreen Widget Tests', () {
    testWidgets('显示注册表单所有元素', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // 验证标题
      expect(find.text('注册账号'), findsOneWidget);

      // 验证表单字段
      expect(find.text('邮箱'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('确认密码'), findsOneWidget);
      expect(find.text('角色'), findsOneWidget);

      // 验证角色选择
      expect(find.text('买手'), findsOneWidget);
      expect(find.text('远程团队'), findsOneWidget);

      // 验证注册按钮
      expect(find.text('注册'), findsOneWidget);
    });

    testWidgets('密码和确认密码必须一致', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // 输入不一致的密码
      await tester.enterText(
        find.widgetWithText(TextField, '密码'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '确认密码'),
        'different',
      );

      // 点击注册按钮
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.text('两次密码不一致'), findsOneWidget);
    });

    testWidgets('选择买手角色', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // 点击买手选项
      await tester.tap(find.text('买手'));
      await tester.pumpAndSettle();

      // 验证买手被选中
      final buyerRadio = find.byWidgetPredicate(
        (widget) =>
            widget is Radio<String> &&
            widget.value == 'buyer' &&
            widget.groupValue == 'buyer',
      );
      expect(buyerRadio, findsOneWidget);
    });

    testWidgets('注册成功后显示颜色标识', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      // 填写完整表单
      await tester.enterText(
        find.widgetWithText(TextField, '邮箱'),
        'newuser@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '密码'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '确认密码'),
        'password123',
      );
      await tester.tap(find.text('买手'));
      await tester.pumpAndSettle();

      // 点击注册按钮
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      // 验证显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
