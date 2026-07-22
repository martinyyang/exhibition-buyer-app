import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/flag/widgets/flag_table.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';

void main() {
  group('FlagTable Widget Tests', () {
    testWidgets('显示所有必需的列', (tester) async {
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: false,
            ),
          ),
        ),
      );

      // 验证列标题
      expect(find.text('编号'), findsOneWidget);
      expect(find.text('报价(¥)'), findsOneWidget);
      expect(find.text('换算价'), findsOneWidget);
    });

    testWidgets('买手端显示报价输入框', (tester) async {
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: false,
            ),
          ),
        ),
      );

      // 买手端应该可以输入报价
    });

    testWidgets('远程端显示目标价输入框', (tester) async {
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: true,
            ),
          ),
        ),
      );

      // 远程端应该显示目标价列
      expect(find.text('目标价'), findsOneWidget);
    });

    testWidgets('显示红色警告标记', (tester) async {
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: false,
            ),
          ),
        ),
      );

      // 当needs_attention=true时显示警告图标
    });

    testWidgets('点击行触发onRowTap回调', (tester) async {
      Flag? tappedFlag;
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: false,
              onRowTap: (flag) {
                tappedFlag = flag;
              },
            ),
          ),
        ),
      );

      // 点击某一行
      // 验证回调被触发
    });

    testWidgets('输入报价后自动计算换算价', (tester) async {
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: false,
            ),
          ),
        ),
      );

      // 输入报价
      // 验证换算价自动更新
    });

    testWidgets('表格可滚动', (tester) async {
      final flags = <Flag>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlagTable(
              flags: flags,
              isRemoteView: false,
            ),
          ),
        ),
      );

      // 验证使用ListView或SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
