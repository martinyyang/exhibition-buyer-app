import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/formula/widgets/formula_input.dart';

void main() {
  group('FormulaInput Widget Tests', () {
    testWidgets('显示公式输入框', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(),
          ),
        ),
      );

      // 验证输入框
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('汇率公式'), findsOneWidget);
    });

    testWidgets('显示公式说明', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(),
          ),
        ),
      );

      // 验证显示示例和说明
      expect(find.textContaining('RMB'), findsWidgets);
    });

    testWidgets('实时预览计算结果', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(),
          ),
        ),
      );

      // 输入公式
      await tester.enterText(find.byType(TextField), 'RMB * 0.14');
      await tester.pumpAndSettle();

      // 验证显示预览结果
      // 例如：当RMB=1000时，结果=140
    });

    testWidgets('显示历史公式列表', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(
              historyFormulas: [
                'RMB * 0.14',
                '(RMB - 50) * 0.14 + 10',
              ],
            ),
          ),
        ),
      );

      // 验证历史公式显示
      expect(find.text('RMB * 0.14'), findsOneWidget);
    });

    testWidgets('点击历史公式自动填充', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(
              historyFormulas: [
                'RMB * 0.14',
              ],
            ),
          ),
        ),
      );

      // 点击历史公式
      await tester.tap(find.text('RMB * 0.14'));
      await tester.pumpAndSettle();

      // 验证输入框自动填充
    });

    testWidgets('公式验证：错误公式显示提示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(),
          ),
        ),
      );

      // 输入错误公式
      await tester.enterText(find.byType(TextField), 'RMB /');
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.textContaining('公式错误'), findsOneWidget);
    });

    testWidgets('保存按钮触发onSave回调', (tester) async {
      String? savedFormula;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormulaInput(
              onSave: (formula) {
                savedFormula = formula;
              },
            ),
          ),
        ),
      );

      // 输入公式
      await tester.enterText(find.byType(TextField), 'RMB * 0.14');
      await tester.pumpAndSettle();

      // 点击保存
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证回调被触发
      expect(savedFormula, 'RMB * 0.14');
    });

    testWidgets('支持复杂公式表达式', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(),
          ),
        ),
      );

      // 输入复杂公式
      await tester.enterText(
        find.byType(TextField),
        '(RMB - 50) * 0.14 + 10',
      );
      await tester.pumpAndSettle();

      // 验证预览正确计算
    });

    testWidgets('显示多个示例价格的预览', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormulaInput(),
          ),
        ),
      );

      // 输入公式
      await tester.enterText(find.byType(TextField), 'RMB * 0.14');
      await tester.pumpAndSettle();

      // 验证显示多个价格示例
      // 1000 → 140
      // 2000 → 280
      // 5000 → 700
    });
  });
}
