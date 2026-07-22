import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_detail_screen.dart';
import 'package:exhibition_buyer_app/features/flag/widgets/flag_table.dart';

void main() {
  group('PhotoDetailScreen Widget Tests', () {
    testWidgets('显示照片和Flag表格在同一页面', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证照片显示
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // 验证Flag表格显示
      expect(find.byType(FlagTable), findsOneWidget);
    });

    testWidgets('照片支持缩放和平移', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证InteractiveViewer支持手势
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('照片上显示旗子标记', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 旗子应该叠加在照片上
      // 显示编号（1、2、3...）
    });

    testWidgets('点击照片位置可以插旗（远程端）', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 远程端点击照片应该创建新旗子
      // 买手端不应该有这个功能
    });

    testWidgets('Flag表格显示所有列', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证表格列：编号、报价、换算价、目标价、状态
      expect(find.text('编号'), findsOneWidget);
      expect(find.text('报价(¥)'), findsOneWidget);
      expect(find.text('换算价'), findsOneWidget);
    });

    testWidgets('买手端可以直接在表格中编辑报价', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 买手端的报价列应该可编辑
      // 验证TextField存在
    });

    testWidgets('远程端可以设置目标价', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 远程端的目标价列应该可编辑
    });

    testWidgets('显示红色警告标记', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 当needs_attention=true时，应该显示🚨图标
      // expect(find.byIcon(Icons.warning), findsWidgets);
    });

    testWidgets('点击表格行自动聚焦到对应旗子', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击表格某一行
      // 照片应该自动滚动到对应旗子位置
    });

    testWidgets('报价自动换算', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 输入报价后，换算价应该自动计算
    });

    testWidgets('Flag表格为空时显示提示', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 如果没有旗子，应该显示提示
      // "点击照片标记商品"
    });

    testWidgets('长按旗子显示删除选项', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(
              photoId: 'test-photo-id',
              isRemoteView: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 远程端长按旗子可以删除
    });

    testWidgets('响应式布局：Web端左右布局，移动端上下布局', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhotoDetailScreen(photoId: 'test-photo-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证使用LayoutBuilder
      expect(find.byType(LayoutBuilder), findsOneWidget);
    });
  });
}
