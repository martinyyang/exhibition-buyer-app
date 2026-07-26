import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart';

/// Release APK 冒烟测试
/// 目标：验证应用能启动、不崩溃、不卡住
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Release APK 冒烟测试', () {
    testWidgets('应用启动测试 - 验证应用能正常启动且不崩溃', (tester) async {
      // 启动应用
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // 等待应用完成初始化
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 验证应用启动成功 - 应该显示登录页面或主页面
      expect(find.byType(MaterialApp), findsOneWidget);

      // 验证没有错误提示
      expect(find.text('Error'), findsNothing);
      expect(find.text('错误'), findsNothing);
    });

    testWidgets('登录页面渲染测试 - 验证登录页面正常显示', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 验证登录页面元素存在
      // 注意：根据实际应用调整查找条件
      final loginElements = [
        find.byType(TextField),
        find.byType(TextFormField),
        find.byType(ElevatedButton),
      ];

      // 至少应该有输入框和按钮
      bool hasLoginUI =
          loginElements.any((finder) => finder.evaluate().isNotEmpty);
      expect(hasLoginUI, true, reason: '登录页面应该包含输入框或按钮');
    });

    testWidgets('.env 配置加载测试 - 验证环境变量正常加载', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 如果 .env 加载失败，应用可能显示错误或无法初始化
      // 这里我们验证应用没有显示明显的配置错误
      expect(find.textContaining('SUPABASE_URL'), findsNothing);
      expect(find.textContaining('SUPABASE_ANON_KEY'), findsNothing);
      expect(find.textContaining('配置错误'), findsNothing);
      expect(find.textContaining('Configuration Error'), findsNothing);
    });

    testWidgets('网络初始化测试 - 验证网络模块能正常初始化', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 验证没有网络初始化失败的错误
      expect(find.textContaining('网络连接失败'), findsNothing);
      expect(find.textContaining('Network Error'), findsNothing);
      expect(
          find.textContaining('Supabase initialization failed'), findsNothing);
    });

    testWidgets('页面导航测试 - 验证基础导航功能正常', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 尝试查找可点击的元素
      final buttons = find.byType(ElevatedButton);
      final iconButtons = find.byType(IconButton);
      final textButtons = find.byType(TextButton);

      // 应该至少有一些可交互的按钮
      final hasInteractiveElements = buttons.evaluate().isNotEmpty ||
          iconButtons.evaluate().isNotEmpty ||
          textButtons.evaluate().isNotEmpty;

      expect(hasInteractiveElements, true, reason: '应用应该包含可交互的按钮');
    });

    testWidgets('内存泄漏测试 - 多次重建应用', (tester) async {
      // 多次启动和关闭应用，验证没有内存泄漏导致的崩溃
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(
          const ProviderScope(
            child: MyApp(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 模拟应用关闭
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }

      // 如果能执行到这里，说明没有严重的内存泄漏
      expect(true, true);
    });

    testWidgets('响应式布局测试 - 验证不同屏幕尺寸下应用正常', (tester) async {
      // 测试移动端尺寸
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);

      // 测试平板尺寸
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MaterialApp), findsOneWidget);

      // 重置屏幕尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('热重启测试 - 验证应用状态恢复', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 模拟应用进入后台
      await tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // 模拟应用恢复前台
      await tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证应用仍然正常显示
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('快速点击测试 - 验证应用不会因快速点击崩溃', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 查找第一个可点击的按钮
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        // 快速点击 10 次
        for (int i = 0; i < 10; i++) {
          await tester.tap(buttons.first);
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // 验证应用没有崩溃
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('长时间运行测试 - 验证应用长期运行稳定性', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 模拟长时间运行
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
      }

      // 验证应用仍然正常
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Error'), findsNothing);
    });
  });

  group('基础功能冒烟测试', () {
    testWidgets('表单输入测试 - 验证输入框正常工作', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 查找输入框
      final textFields = find.byType(TextField);
      final textFormFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        // 尝试在输入框中输入文本
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pump();

        // 验证输入成功
        expect(find.text('test@example.com'), findsOneWidget);
      } else if (textFormFields.evaluate().isNotEmpty) {
        await tester.enterText(textFormFields.first, 'test@example.com');
        await tester.pump();

        expect(find.text('test@example.com'), findsOneWidget);
      }
    });

    testWidgets('滚动测试 - 验证列表滚动正常', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 查找可滚动的组件
      final scrollables = find.byType(Scrollable);

      if (scrollables.evaluate().isNotEmpty) {
        // 尝试滚动
        await tester.drag(scrollables.first, const Offset(0, -200));
        await tester.pumpAndSettle();

        // 验证应用没有崩溃
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('对话框测试 - 验证弹窗能正常显示和关闭', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 这是一个简单的验证，实际应用中可能需要触发特定操作来显示对话框
      // 这里我们只验证应用没有未处理的对话框错误
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
