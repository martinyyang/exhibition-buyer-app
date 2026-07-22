import 'package:flutter_test/flutter_test.dart';
import 'package:展会专用APP/features/formula/services/formula_calculator.dart';

void main() {
  group('FormulaCalculator单元测试', () {
    group('基础公式计算', () {
      test('简单乘法 - RMB * 0.14', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 1000);
        expect(result, 140.0);
      });

      test('简单除法 - RMB / 7.2', () {
        final result = FormulaCalculator.calculate('RMB / 7.2', 720);
        expect(result, 100.0);
      });

      test('简单加法 - RMB + 100', () {
        final result = FormulaCalculator.calculate('RMB + 100', 500);
        expect(result, 600.0);
      });

      test('简单减法 - RMB - 50', () {
        final result = FormulaCalculator.calculate('RMB - 50', 1000);
        expect(result, 950.0);
      });
    });

    group('复杂公式计算', () {
      test('括号表达式 - (RMB - 50) * 0.14', () {
        final result = FormulaCalculator.calculate('(RMB - 50) * 0.14', 1000);
        expect(result, 133.0);
      });

      test('多重运算 - (RMB - 50) * 0.14 + 10', () {
        final result = FormulaCalculator.calculate('(RMB - 50) * 0.14 + 10', 1000);
        expect(result, 143.0);
      });

      test('嵌套括号 - ((RMB - 100) / 2) * 0.14', () {
        final result = FormulaCalculator.calculate('((RMB - 100) / 2) * 0.14', 1000);
        expect(result, 63.0);
      });

      test('混合运算 - RMB * 0.14 + RMB * 0.01', () {
        final result = FormulaCalculator.calculate('RMB * 0.14 + RMB * 0.01', 1000);
        expect(result, 150.0);
      });
    });

    group('边界情况', () {
      test('零值价格', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 0);
        expect(result, 0.0);
      });

      test('小数价格', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 999.99);
        expect(result, 140.0);
      });

      test('大数值价格', () {
        final result = FormulaCalculator.calculate('RMB * 0.14', 999999);
        expect(result, 139999.86);
      });

      test('负数结果（折扣场景）', () {
        final result = FormulaCalculator.calculate('RMB - 2000', 1000);
        expect(result, -1000.0);
      });
    });

    group('公式验证', () {
      test('有效公式验证 - 返回true', () {
        expect(FormulaCalculator.validateFormula('RMB * 0.14'), true);
        expect(FormulaCalculator.validateFormula('(RMB - 50) * 0.14 + 10'), true);
      });

      test('无效公式验证 - 返回false', () {
        expect(FormulaCalculator.validateFormula('RMB *'), false);
        expect(FormulaCalculator.validateFormula('RMB / 0'), false);
        expect(FormulaCalculator.validateFormula('invalid formula'), false);
        expect(FormulaCalculator.validateFormula(''), false);
      });

      test('公式缺少操作数', () {
        expect(FormulaCalculator.validateFormula('RMB + '), false);
      });

      test('公式括号不匹配', () {
        expect(FormulaCalculator.validateFormula('(RMB * 0.14'), false);
        expect(FormulaCalculator.validateFormula('RMB * 0.14)'), false);
      });
    });

    group('公式预览', () {
      test('预览多个测试价格', () {
        final testPrices = [100.0, 500.0, 1000.0, 5000.0];
        final results = FormulaCalculator.preview('RMB * 0.14', testPrices);

        expect(results[100.0], 14.0);
        expect(results[500.0], 70.0);
        expect(results[1000.0], 140.0);
        expect(results[5000.0], 700.0);
      });

      test('预览复杂公式', () {
        final testPrices = [1000.0, 2000.0];
        final results = FormulaCalculator.preview('(RMB - 50) * 0.14 + 10', testPrices);

        expect(results[1000.0], 143.0);
        expect(results[2000.0], 283.0);
      });

      test('预览错误公式 - 返回0', () {
        final testPrices = [1000.0];
        final results = FormulaCalculator.preview('invalid', testPrices);

        expect(results[1000.0], 0.0);
      });
    });

    group('错误处理', () {
      test('除以零异常', () {
        expect(
          () => FormulaCalculator.calculate('RMB / 0', 1000),
          throwsA(isA<FormatException>()),
        );
      });

      test('无效公式抛出异常', () {
        expect(
          () => FormulaCalculator.calculate('RMB *', 1000),
          throwsA(isA<FormatException>()),
        );
      });

      test('空公式抛出异常', () {
        expect(
          () => FormulaCalculator.calculate('', 1000),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
