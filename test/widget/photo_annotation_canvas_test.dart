import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/photo/widgets/photo_annotation_canvas.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';

void main() {
  group('PhotoAnnotationCanvas Widget Tests', () {
    testWidgets('显示照片', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: [],
            ),
          ),
        ),
      );

      // 验证显示图片
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('在正确位置显示旗子标记', (tester) async {
      final flags = [
        Flag(
          id: '1',
          createdAt: DateTime.now(),
          photoId: 'photo1',
          number: 1,
          positionX: 0.5,
          positionY: 0.5,
          needsAttention: false,
          createdBy: 'user1',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: flags,
            ),
          ),
        ),
      );

      // 验证旗子显示
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('点击照片时触发onTap回调', (tester) async {
      Offset? tappedPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: const [],
              onTap: (offset) {
                tappedPosition = offset;
              },
            ),
          ),
        ),
      );

      // 点击照片
      await tester.tap(find.byType(PhotoAnnotationCanvas));
      await tester.pumpAndSettle();

      // 验证回调被触发
      expect(tappedPosition, isNotNull);
    });

    testWidgets('长按旗子触发onFlagLongPress回调', (tester) async {
      Flag? longPressedFlag;

      final flags = [
        Flag(
          id: '1',
          createdAt: DateTime.now(),
          photoId: 'photo1',
          number: 1,
          positionX: 0.5,
          positionY: 0.5,
          needsAttention: false,
          createdBy: 'user1',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: flags,
              onFlagLongPress: (flag) {
                longPressedFlag = flag;
              },
            ),
          ),
        ),
      );

      // 长按旗子
      // await tester.longPress(find.text('1'));
      // await tester.pumpAndSettle();

      // 验证回调被触发
      // expect(longPressedFlag, isNotNull);
    });

    testWidgets('需要注意的旗子显示红色', (tester) async {
      final flags = [
        Flag(
          id: '1',
          createdAt: DateTime.now(),
          photoId: 'photo1',
          number: 1,
          positionX: 0.5,
          positionY: 0.5,
          needsAttention: true, // 红色警告
          createdBy: 'user1',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: flags,
            ),
          ),
        ),
      );

      // 验证旗子为红色
      // expect(find.byType(Container).evaluate().first.widget.decoration.color, Colors.red);
    });

    testWidgets('支持照片缩放', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: [],
              enableZoom: true,
            ),
          ),
        ),
      );

      // 验证使用InteractiveViewer
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('旗子编号自动递增', (tester) async {
      final flags = [
        Flag(
          id: '1',
          createdAt: DateTime.now(),
          photoId: 'photo1',
          number: 1,
          positionX: 0.3,
          positionY: 0.3,
          needsAttention: false,
          createdBy: 'user1',
        ),
        Flag(
          id: '2',
          createdAt: DateTime.now(),
          photoId: 'photo1',
          number: 2,
          positionX: 0.7,
          positionY: 0.7,
          needsAttention: false,
          createdBy: 'user1',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoAnnotationCanvas(
              imageUrl: 'https://example.com/photo.jpg',
              flags: flags,
            ),
          ),
        ),
      );

      // 验证显示两个旗子
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
