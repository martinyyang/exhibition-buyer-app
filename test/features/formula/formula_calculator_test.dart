import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/features/formula/services/formula_calculator.dart';

void main() {
  group('Price Conversion Formula Tests', () {
    test('RMB/6.75 formula converts prices correctly', () {
      const formula = 'RMB/6.75';

      // Test case 1: ¥1000 → 148.15
      final result1 = FormulaCalculator.calculate(formula, 1000);
      expect(result1, 148.15);

      // Test case 2: ¥2000 → 296.30
      final result2 = FormulaCalculator.calculate(formula, 2000);
      expect(result2, 296.30);

      // Test case 3: ¥5000 → 740.74
      final result3 = FormulaCalculator.calculate(formula, 5000);
      expect(result3, 740.74);
    });

    test('RMB/7.0 formula converts prices correctly', () {
      const formula = 'RMB/7.0';

      // Test case 1: ¥1000 → 142.86
      final result1 = FormulaCalculator.calculate(formula, 1000);
      expect(result1, 142.86);

      // Test case 2: ¥2000 → 285.71
      final result2 = FormulaCalculator.calculate(formula, 2000);
      expect(result2, 285.71);

      // Test case 3: ¥7000 → 1000.00
      final result3 = FormulaCalculator.calculate(formula, 7000);
      expect(result3, 1000.00);
    });

    test('Formula with multiplication converts correctly', () {
      const formula = 'RMB*0.15';

      // Test: ¥1000 * 0.15 → 150.00
      final result = FormulaCalculator.calculate(formula, 1000);
      expect(result, 150.00);
    });

    test('Formula with addition converts correctly', () {
      const formula = 'RMB+100';

      // Test: ¥1000 + 100 → 1100.00
      final result = FormulaCalculator.calculate(formula, 1000);
      expect(result, 1100.00);
    });

    test('Formula with subtraction converts correctly', () {
      const formula = 'RMB-50';

      // Test: ¥1000 - 50 → 950.00
      final result = FormulaCalculator.calculate(formula, 1000);
      expect(result, 950.00);
    });

    test('Complex formula with parentheses converts correctly', () {
      const formula = '(RMB - 50) * 0.14 + 10';

      // Test: (¥1000 - 50) * 0.14 + 10 → 143.00
      final result = FormulaCalculator.calculate(formula, 1000);
      expect(result, 143.00);
    });

    test('Zero seller price returns zero', () {
      const formula = 'RMB/6.75';

      final result = FormulaCalculator.calculate(formula, 0);
      expect(result, 0.0);
    });

    test('Invalid formula throws FormatException', () {
      expect(
        () => FormulaCalculator.calculate('invalid', 1000),
        throwsA(isA<FormatException>()),
      );
    });

    test('Division by zero throws FormatException', () {
      expect(
        () => FormulaCalculator.calculate('RMB/0', 1000),
        throwsA(isA<FormatException>()),
      );
    });

    test('validateFormula returns true for valid formula', () {
      const formula = 'RMB/6.75';
      expect(FormulaCalculator.validateFormula(formula), true);
    });

    test('validateFormula returns false for invalid formula', () {
      const formula = 'invalid';
      expect(FormulaCalculator.validateFormula(formula), false);
    });

    test('preview returns correct results for multiple prices', () {
      const formula = 'RMB/6.75';
      final testPrices = [1000.0, 2000.0, 5000.0];

      final results = FormulaCalculator.preview(formula, testPrices);

      expect(results[1000.0], 148.15);
      expect(results[2000.0], 296.30);
      expect(results[5000.0], 740.74);
    });

    test('preview handles invalid formula gracefully', () {
      const formula = 'invalid';
      final testPrices = [1000.0];

      final results = FormulaCalculator.preview(formula, testPrices);

      expect(results[1000.0], 0.0);
    });
  });
}
