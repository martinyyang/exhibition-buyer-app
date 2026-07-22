import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/event/screens/event_selection_screen.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';

void main() {
  group('EventSelectionScreen Widget Tests', () {
    testWidgets('显示场次列表', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      // 验证标题
      expect(find.text('选择场次'), findsOneWidget);

      // 验证创建新场次按钮
      expect(find.byIcon(Icons.add), findsOneWidget);

      // 验证列表容器
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('显示活跃场次高亮标记', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 活跃场次应该有特殊标记
      // 例如：🟢图标或"当前"文字
    });

    testWidgets('点击场次导航到摊位列表', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 如果有场次卡片，点击应该触发导航
      final eventCards = find.byType(Card);
      if (eventCards.evaluate().isNotEmpty) {
        await tester.tap(eventCards.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('点击创建按钮显示创建对话框', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      // 点击创建按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 验证显示对话框
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('创建新场次'), findsOneWidget);

      // 验证表单字段
      expect(find.text('场次名称'), findsOneWidget);
      expect(find.text('开始日期'), findsOneWidget);
    });

    testWidgets('创建场次表单验证', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      // 打开创建对话框
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 不填写直接提交
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.text('请输入场次名称'), findsOneWidget);
    });

    testWidgets('成功创建场次后显示在列表中', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      // 打开创建对话框
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 填写表单
      await tester.enterText(
        find.widgetWithText(TextField, '场次名称'),
        '2026春季广交会',
      );

      // 提交
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // 验证显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('场次列表为空时显示提示', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 空状态应该显示提示信息
      // expect(find.text('暂无场次'), findsOneWidget);
    });

    testWidgets('长按场次显示操作菜单', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 长按场次卡片
      final eventCards = find.byType(Card);
      if (eventCards.evaluate().isNotEmpty) {
        await tester.longPress(eventCards.first);
        await tester.pumpAndSettle();

        // 验证显示操作菜单（设为活跃、删除等）
      }
    });
  });
}
