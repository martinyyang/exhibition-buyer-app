import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exhibition_buyer_app/core/utils/color_generator.dart';

void main() {
  group('ColorGenerator', () {
    group('assignRandomColor', () {
      test('返回有效的颜色名称', () {
        final color = ColorGenerator.assignRandomColor();

        expect(
          ['green', 'blue', 'yellow', 'red', 'purple', 'orange'],
          contains(color),
        );
      });

      test('多次调用返回的颜色都在允许范围内', () {
        for (var i = 0; i < 20; i++) {
          final color = ColorGenerator.assignRandomColor();
          expect(
            ['green', 'blue', 'yellow', 'red', 'purple', 'orange'],
            contains(color),
          );
        }
      });
    });

    group('getColorByName', () {
      test('green返回绿色', () {
        expect(ColorGenerator.getColorByName('green'), Colors.green);
      });

      test('blue返回蓝色', () {
        expect(ColorGenerator.getColorByName('blue'), Colors.blue);
      });

      test('yellow返回黄色', () {
        expect(ColorGenerator.getColorByName('yellow'), Colors.yellow);
      });

      test('red返回红色', () {
        expect(ColorGenerator.getColorByName('red'), Colors.red);
      });

      test('purple返回紫色', () {
        expect(ColorGenerator.getColorByName('purple'), Colors.purple);
      });

      test('orange返回橙色', () {
        expect(ColorGenerator.getColorByName('orange'), Colors.orange);
      });

      test('未知颜色名称返回灰色', () {
        expect(ColorGenerator.getColorByName('unknown'), Colors.grey);
      });

      test('空字符串返回灰色', () {
        expect(ColorGenerator.getColorByName(''), Colors.grey);
      });
    });

    group('getChineseName', () {
      test('green返回"绿色"', () {
        expect(ColorGenerator.getChineseName('green'), '绿色');
      });

      test('blue返回"蓝色"', () {
        expect(ColorGenerator.getChineseName('blue'), '蓝色');
      });

      test('yellow返回"黄色"', () {
        expect(ColorGenerator.getChineseName('yellow'), '黄色');
      });

      test('red返回"红色"', () {
        expect(ColorGenerator.getChineseName('red'), '红色');
      });

      test('purple返回"紫色"', () {
        expect(ColorGenerator.getChineseName('purple'), '紫色');
      });

      test('orange返回"橙色"', () {
        expect(ColorGenerator.getChineseName('orange'), '橙色');
      });

      test('未知颜色返回"未知"', () {
        expect(ColorGenerator.getChineseName('unknown'), '未知');
      });
    });

    group('getColorEmoji', () {
      test('green返回绿色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('green'), '🟢');
      });

      test('blue返回蓝色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('blue'), '🔵');
      });

      test('yellow返回黄色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('yellow'), '🟡');
      });

      test('red返回红色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('red'), '🔴');
      });

      test('purple返回紫色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('purple'), '🟣');
      });

      test('orange返回橙色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('orange'), '🟠');
      });

      test('未知颜色返回白色圆圈emoji', () {
        expect(ColorGenerator.getColorEmoji('unknown'), '⚪');
      });
    });

    group('完整性测试', () {
      test('所有颜色名称都有对应的Color、中文名和Emoji', () {
        for (final colorName in ColorGenerator.colorNames) {
          // 测试Color映射
          final color = ColorGenerator.getColorByName(colorName);
          expect(color, isNot(Colors.grey));

          // 测试中文名映射
          final chineseName = ColorGenerator.getChineseName(colorName);
          expect(chineseName, isNot('未知'));

          // 测试Emoji映射
          final emoji = ColorGenerator.getColorEmoji(colorName);
          expect(emoji, isNot('⚪'));
        }
      });

      test('colorNames和availableColors数量一致', () {
        expect(
          ColorGenerator.colorNames.length,
          ColorGenerator.availableColors.length,
        );
      });
    });
  });
}
