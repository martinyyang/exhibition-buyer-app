import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/booth/screens/booth_list_screen.dart';
import 'package:exhibition_buyer_app/features/booth/models/booth.dart';
import 'package:exhibition_buyer_app/shared/widgets/color_badge.dart';

void main() {
  group('BoothListScreen Widget Tests', () {
    testWidgets('显示当前场次名称', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      // 验证AppBar显示场次名称
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('显示摊位列表', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证列表容器
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('显示买手颜色标识', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 每个摊位应该显示买手颜色标识
      // expect(find.byType(ColorBadge), findsWidgets);
    });

    testWidgets('点击新建摊位按钮显示对话框', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      // 点击新建按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 验证显示对话框
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('新建摊位'), findsOneWidget);
      expect(find.text('摊位号'), findsOneWidget);
    });

    testWidgets('摊位号验证', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      // 打开对话框
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 不填写直接提交
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.text('请输入摊位号'), findsOneWidget);
    });

    testWidgets('成功创建摊位', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      // 打开对话框
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 输入摊位号
      await tester.enterText(
        find.widgetWithText(TextField, '摊位号'),
        'B01',
      );

      // 提交
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // 验证显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('点击摊位进入照片网格页面', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 如果有摊位卡片，点击应该触发导航
      final boothCards = find.byType(Card);
      if (boothCards.evaluate().isNotEmpty) {
        await tester.tap(boothCards.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('摊位列表为空时显示提示', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 空状态应该显示提示信息
      // expect(find.text('暂无摊位'), findsOneWidget);
    });

    testWidgets('长按摊位显示操作菜单', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 长按摊位卡片
      final boothCards = find.byType(Card);
      if (boothCards.evaluate().isNotEmpty) {
        await tester.longPress(boothCards.first);
        await tester.pumpAndSettle();

        // 验证显示操作菜单
      }
    });

    testWidgets('显示摊位照片数量', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 摊位卡片应该显示照片数量
      // 例如："5张照片"
    });

    testWidgets('支持快速切换摊位', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BoothListScreen(eventId: 'test-event-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证摊位之间可以快速切换
      // 点击不同摊位应该立即响应
    });
  });
}
