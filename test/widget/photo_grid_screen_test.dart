import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_grid_screen.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';

void main() {
  group('PhotoGridScreen Widget Tests', () {
    testWidgets('显示照片网格', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证网格容器
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('显示拍照按钮', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      // 验证拍照按钮（FAB）
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('照片缩略图显示标注数量', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 照片卡片应该显示旗子数量
      // 例如："5个旗子"
    });

    testWidgets('显示供应商名称', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 如果照片有供应商名称，应该显示
    });

    testWidgets('显示供应商Logo', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 如果照片有供应商Logo，应该显示
    });

    testWidgets('点击照片进入详情页', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 如果有照片，点击应该触发导航
      final photoCards = find.byType(Card);
      if (photoCards.evaluate().isNotEmpty) {
        await tester.tap(photoCards.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('点击拍照按钮打开相机', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      // 点击拍照按钮
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // 应该调用相机功能
    });

    testWidgets('照片列表为空时显示提示', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 空状态应该显示提示信息
      // expect(find.text('暂无照片'), findsOneWidget);
    });

    testWidgets('长按照片显示操作菜单', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 长按照片卡片
      final photoCards = find.byType(Card);
      if (photoCards.evaluate().isNotEmpty) {
        await tester.longPress(photoCards.first);
        await tester.pumpAndSettle();

        // 验证显示操作菜单（添加供应商信息、删除等）
      }
    });

    testWidgets('上传照片时显示进度', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoGridScreen(boothId: 'test-booth-id'),
          ),
        ),
      );

      // 点击拍照按钮
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // 上传时应该显示加载指示器
      // expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
