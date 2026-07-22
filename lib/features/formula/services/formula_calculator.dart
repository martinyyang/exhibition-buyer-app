import 'package:math_expressions/math_expressions.dart';

class FormulaCalculator {
  /// 根据公式计算换算价格
  /// formula: 公式字符串，如 "RMB * 0.14" 或 "(RMB - 50) * 0.14 + 10"
  /// rmbPrice: 人民币价格
  /// 返回换算后的价格
  static double calculate(String formula, double rmbPrice) {
    try {
      // 将公式中的 RMB 替换为实际价格
      final formulaWithValue = formula.replaceAll('RMB', rmbPrice.toString());

      // 解析并计算公式
      final parser = Parser();
      final expression = parser.parse(formulaWithValue);
      final contextModel = ContextModel();

      final result = expression.evaluate(EvaluationType.REAL, contextModel);

      return double.parse(result.toStringAsFixed(2));
    } catch (e) {
      throw FormatException('公式错误: $e');
    }
  }

  /// 验证公式是否有效
  static bool validateFormula(String formula) {
    try {
      // 用测试值验证公式
      calculate(formula, 1000);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 预览公式计算结果
  /// 返回多个示例价格的计算结果
  static Map<double, double> preview(String formula, List<double> testPrices) {
    final results = <double, double>{};

    for (final price in testPrices) {
      try {
        results[price] = calculate(formula, price);
      } catch (e) {
        results[price] = 0.0;
      }
    }

    return results;
  }
}
