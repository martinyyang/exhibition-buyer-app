import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/dashboard/screens/web_dashboard_screen.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';

void main() {
  group('WebDashboardLayout Widget测试', () {
    late Photo testPhoto;
    late List<Flag> testFlags;

    setUp(() {
      testPhoto = Photo(
        id: 'photo-1',
        boothId: 'booth-1',
        url: 'https://example.com/photo.jpg',
        supplierName: 'Test Supplier',
      );

      testFlags = [
        Flag(
          id: 'flag-1',
          photoId: 'photo-1',
          number: 1,
          positionX: 0.3,
          positionY: 0.4,
          priceRmb: 1000,
        ),
        Flag(
          id: 'flag-2',
          photoId: 'photo-1',
          number: 2,
          positionX: 0.6,
          positionY: 0.5,
          priceRmb: 2000,
        ),
      ];
    });

    testWidgets('渲染三栏布局（买手列表、照片、Flag表格）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) ,
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      // 验证AppBar
      expect(find.text('远程审核 - Web端'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // 验证买手列表侧边栏
      expect(find.text('买手列表'), findsOneWidget);
      expect(find.text('买手A'), findsOneWidget);
      expect(find.text('买手B'), findsOneWidget);
      expect(find.text('买手C'), findsOneWidget);

      // 验证照片区域工具栏
      expect(find.text('摊位号: booth-1'), findsOneWidget);
      expect(find.text('Test Supplier'), findsOneWidget);
      expect(find.text('2 个标注'), findsOneWidget);

      // 验证Flag表格侧边栏
      expect(find.text('标注详情'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('买手列表显示在线状态', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      // 验证在线买手显示绿色圆点
      final greenCircles = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.green,
          ),
        ),
      );

      // 买手A和买手B在线，应该有2个绿色圆点
      expect(greenCircles.length, greaterThanOrEqualTo(2));
    });

    testWidgets('买手列表显示照片数量', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      expect(find.text('15 张照片'), findsOneWidget);
      expect(find.text('12 张照片'), findsOneWidget);
      expect(find.text('8 张照片'), findsOneWidget);
    });

    testWidgets('照片区域显示供应商信息', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.text('Test Supplier'), findsOneWidget);
    });

    testWidgets('照片区域不显示供应商信息（当为null时）', (tester) async {
      final photoWithoutSupplier = Photo(
        id: 'photo-1',
        boothId: 'booth-1',
        url: 'https://example.com/photo.jpg',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: photoWithoutSupplier,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.store), findsNothing);
    });

    testWidgets('照片区域显示标注数量', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      expect(find.text('2 个标注'), findsOneWidget);
    });

    testWidgets('照片区域显示标注数量为0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: const [],
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      expect(find.text('0 个标注'), findsOneWidget);
    });

    testWidgets('左侧边栏宽度固定为280', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      final buyerSidebar = tester.widget<Container>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.width == 280 &&
                widget.decoration is BoxDecoration,
          ),
        ).first,
      );

      expect(buyerSidebar.width, 280);
    });

    testWidgets('右侧边栏宽度固定为400', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      final flagSidebar = tester.widget<Container>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.width == 400 &&
                widget.decoration is BoxDecoration,
          ),
        ).first,
      );

      expect(flagSidebar.width, 400);
    });

    testWidgets('点击设置按钮（TODO）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // TODO功能，暂不验证
    });

    testWidgets('点击刷新按钮（TODO）', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: WebDashboardLayout(
              photo: testPhoto,
              flags: testFlags,
              onAddFlag: (offset) {},
              onUpdateFlag: (flag) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // TODO功能，暂不验证
    });
  });
}
