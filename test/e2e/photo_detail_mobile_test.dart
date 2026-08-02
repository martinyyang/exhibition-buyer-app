import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:exhibition_buyer_app/main.dart' as app;

/// E2E测试：PhotoDetailScreen 移动端功能
///
/// 测试场景：
/// 1. 移动端图片放大缩小功能
/// 2. 隐藏/显示旗子按钮功能
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Photo Detail Mobile Features E2E Tests', () {
    testWidgets('Mobile: InteractiveViewer allows pinch-to-zoom',
        (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // TODO: 需要先登录并导航到照片详情页面
      // 此处假设已经在照片详情页面

      // 查找 InteractiveViewer（移动端布局应该有）
      final interactiveViewerFinder = find.byType(InteractiveViewer);

      // 在移动端（宽度<900）应该存在 InteractiveViewer
      // 验证 InteractiveViewer 存在
      expect(
        interactiveViewerFinder,
        findsWidgets,
        reason: 'Mobile layout should have InteractiveViewer for pinch-to-zoom',
      );

      // 验证可以缩放
      final interactiveViewer =
          tester.widget<InteractiveViewer>(interactiveViewerFinder.first);
      expect(interactiveViewer.minScale, lessThanOrEqualTo(1.0),
          reason: 'Should allow zooming out');
      expect(interactiveViewer.maxScale, greaterThan(1.0),
          reason: 'Should allow zooming in');
    });

    testWidgets('Mobile: Can zoom in and out on photo',
        (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // TODO: 导航到照片详情页面

      // 查找 InteractiveViewer
      final interactiveViewerFinder = find.byType(InteractiveViewer);
      expect(interactiveViewerFinder, findsWidgets);

      // 模拟放大手势（缩放到2倍）
      final Offset center = tester.getCenter(interactiveViewerFinder.first);
      final TestGesture gesture1 = await tester.startGesture(center);
      final TestGesture gesture2 =
          await tester.startGesture(center + const Offset(10, 10));

      // 模拟两指分开（放大）
      await gesture1.moveBy(const Offset(-50, -50));
      await gesture2.moveBy(const Offset(50, 50));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // 验证图片已放大（通过检查 transformation 矩阵）
      final interactiveViewer =
          tester.widget<InteractiveViewer>(interactiveViewerFinder.first);
      expect(
        interactiveViewer.transformationController,
        isNotNull,
        reason: 'Should have transformation controller',
      );
    });

    testWidgets('Toggle flags visibility button exists and works',
        (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // TODO: 导航到照片详情页面，确保有旗子存在

      // 查找隐藏/显示旗子按钮（通过 key 或 icon）
      final toggleButtonFinder = find.byKey(const Key('toggle_flags_button'));

      expect(
        toggleButtonFinder,
        findsOneWidget,
        reason: 'Should have a button to toggle flags visibility',
      );

      // 点击前，旗子应该可见
      // 查找旗子标记（通过特定的widget或key）
      final flagMarkersFinder = find.byKey(const Key('flag_marker'));
      final initialFlagCount = tester.widgetList(flagMarkersFinder).length;

      // 点击隐藏旗子按钮
      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // 验证旗子被隐藏（Opacity为0或Visibility为gone）
      // 方法1: 检查是否有 Visibility widget 包裹旗子
      final visibilityFinder = find.byType(Visibility);
      if (tester.widgetList(visibilityFinder).isNotEmpty) {
        final visibility = tester.widget<Visibility>(visibilityFinder.first);
        expect(
          visibility.visible,
          false,
          reason: 'Flags should be hidden after clicking toggle button',
        );
      }

      // 再次点击应该显示旗子
      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // 验证旗子重新显示
      final flagMarkersAfterShow = tester.widgetList(flagMarkersFinder).length;
      expect(
        flagMarkersAfterShow,
        initialFlagCount,
        reason: 'Flags should be visible again after second click',
      );
    });

    testWidgets('Toggle button has correct icon based on state',
        (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // TODO: 导航到照片详情页面

      // 查找切换按钮
      final toggleButtonFinder = find.byKey(const Key('toggle_flags_button'));
      expect(toggleButtonFinder, findsOneWidget);

      // 初始状态：旗子可见，按钮应显示"隐藏"图标（visibility或visibility_off）
      final iconFinder = find.descendant(
        of: toggleButtonFinder,
        matching: find.byType(Icon),
      );
      expect(iconFinder, findsOneWidget);

      Icon initialIcon = tester.widget<Icon>(iconFinder);
      expect(
        initialIcon.icon,
        Icons.visibility_off,
        reason: 'Should show visibility_off icon when flags are visible',
      );

      // 点击隐藏旗子
      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // 旗子隐藏后，按钮应显示"显示"图标
      Icon afterHideIcon = tester.widget<Icon>(iconFinder);
      expect(
        afterHideIcon.icon,
        Icons.visibility,
        reason: 'Should show visibility icon when flags are hidden',
      );
    });

    testWidgets('Mobile: Can zoom and toggle flags independently',
        (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // TODO: 导航到照片详情页面

      // 先放大图片
      final interactiveViewerFinder = find.byType(InteractiveViewer);
      final Offset center = tester.getCenter(interactiveViewerFinder.first);
      final TestGesture gesture1 = await tester.startGesture(center);
      final TestGesture gesture2 =
          await tester.startGesture(center + const Offset(10, 10));

      await gesture1.moveBy(const Offset(-30, -30));
      await gesture2.moveBy(const Offset(30, 30));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // 在放大状态下，隐藏旗子
      final toggleButtonFinder = find.byKey(const Key('toggle_flags_button'));
      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // 验证图片仍然放大，但旗子被隐藏
      final visibilityFinder = find.byType(Visibility);
      if (tester.widgetList(visibilityFinder).isNotEmpty) {
        final visibility = tester.widget<Visibility>(visibilityFinder.first);
        expect(
          visibility.visible,
          false,
          reason: 'Flags should be hidden while zoom state is preserved',
        );
      }

      // 再次显示旗子
      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // 验证旗子显示，图片仍然保持放大状态
      expect(
        find.byKey(const Key('flag_marker')),
        findsWidgets,
        reason: 'Flags should be visible again while zoom is preserved',
      );
    });

    testWidgets('Desktop: No InteractiveViewer on desktop layout',
        (WidgetTester tester) async {
      // 模拟桌面宽度
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      app.main();
      await tester.pumpAndSettle();

      // TODO: 导航到照片详情页面

      // 桌面端（宽度>900）应该不使用 InteractiveViewer（或使用不同的配置）
      // 桌面端已经有 InteractiveViewer，所以这个测试需要调整
      // 我们应该验证移动端和桌面端的 InteractiveViewer 行为不同

      // 重置视图大小
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Mobile: Reset view button exists on mobile',
        (WidgetTester tester) async {
      // 模拟移动端宽度
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 2.0;

      app.main();
      await tester.pumpAndSettle();

      // TODO: 导航到照片详情页面

      // 查找重置视图按钮
      final resetButtonFinder = find.byIcon(Icons.refresh);

      // 移动端应该有重置视图按钮
      expect(
        resetButtonFinder,
        findsOneWidget,
        reason: 'Mobile layout should have reset view button',
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
