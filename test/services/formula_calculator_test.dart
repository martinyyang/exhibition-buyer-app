import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/formula/services/formula_calculator.dart';

void main() {
  group('FormulaCalculator', () {
    group('validateFormula', () {
      test('验证合法的简单公式', () {
        expect(FormulaCalculator.validateFormula('RMB * 0.14'), isTrue);
        expect(FormulaCalculator.validateFormula('RMB + 100'), isTrue);
        expect(FormulaCalculator.validateFormula('RMB - 50'), isTrue);
        expect(FormulaCalculator.validateFormula('RMB / 2'), isTrue);
      });

      test('验证合法的复杂公式', () {
        expect(FormulaCalculator.validateFormula('(RMB - 50) * 0.14'), isTrue);
        expect(FormulaCalculator.validateFormula('(RMB - 50) * 0.14 + 10'), isTrue);
        expect(FormulaCalculator.validateFormula('RMB * 0.14 / 2'), isTrue);
      });

      test('拒绝不包含RMB变量的公式', () {
        expect(FormulaCalculator.validateFormula('100 * 0.14'), isFalse);
        expect(FormulaCalculator.validateFormula('0.14'), isFalse);
      });

      test('拒绝语法错误的公式', () {
        expect(FormulaCalculator.validateFormula('RMB *'), isFalse);
        expect(FormulaCalculator.validateFormula('RMB + + 100'), isFalse);
        expect(FormulaCalculator.validateFormula('(RMB * 0.14'), isFalse);
        expect(FormulaCalculator.validateFormula('RMB)'), isFalse);
      });

      test('拒绝空公式', () {
        expect(FormulaCalculator.validateFormula(''), isFalse);
        expect(FormulaCalculator.validateFormula('   '), isFalse);
      });

      test('拒绝包含非法字符的公式', () {
        expect(FormulaCalculator.validateFormula('RMB * 0.14; DROP TABLE'), isFalse);
        expect(FormulaCalculator.validateFormula('RMB & 100'), isFalse);
      });
    });

    group('calculate', () {
      test('计算简单乘法', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 1000);
        expect(result, 140.0);
      });

      test('计算简单加法', () {
        final result = FormulaCalculator.calculate('RMB + 100', 1000);
        expect(result, 1100.0);
      });

      test('计算简单减法', () {
        final result = FormulaCalculator.calculate('RMB - 50', 1000);
        expect(result, 950.0);
      });

      test('计算简单除法', () {
        final result = FormulaCalculator.calculate('RMB / 2', 1000);
        expect(result, 500.0);
      });

      test('计算复杂公式', () {
        final result = FormulaCalculator.calculate('(RMB - 50) * 0.14', 1000);
        expect(result, 133.0);
      });

      test('计算多步骤公式', () {
        final result = FormulaCalculator.calculate('(RMB - 50) * 0.14 + 10', 1000);
        expect(result, 143.0);
      });

      test('处理小数运算', () {
        final result = FormulaCalculator.calculate('RMB * 0.145', 1000);
        expect(result, 145.0);
      });

      test('处理负数结果', () {
        final result = FormulaCalculator.calculate('RMB - 2000', 1000);
        expect(result, -1000.0);
      });

      test('除以0抛出异常', () {
        expect(
          () => FormulaCalculator.calculate('RMB / 0', 1000),
          throwsException,
        );
      });

      test('非法公式抛出异常', () {
        expect(
          () => FormulaCalculator.calculate('RMB *', 1000),
          throwsException,
        );
      });
    });

    group('preview', () {
      test('预览多个价格的计算结果', () {
        final results = FormulaCalculator.preview('RMB * 0.14', [1000, 2000, 5000]);

        expect(results[1000], 140.0);
        expect(results[2000], 280.0);
        expect(results[5000], 700.0);
      });

      test('预览复杂公式', () {
        final results = FormulaCalculator.preview(
          '(RMB - 50) * 0.14 + 10',
          [1000, 2000],
        );

        expect(results[1000], 143.0);
        expect(results[2000], 283.0);
      });

      test('空价格列表返回空结果', () {
        final results = FormulaCalculator.preview('RMB * 0.14', []);
        expect(results, isEmpty);
      });
    });

    group('边界情况', () {
      test('处理超大数字', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 1000000);
        expect(result, 140000.0);
      });

      test('处理超小数字', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 0.01);
        expect(result, closeTo(0.0014, 0.0001));
      });

      test('处理0价格', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 0);
        expect(result, 0.0);
      });
    });
  });
}
