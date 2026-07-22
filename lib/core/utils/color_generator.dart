import 'dart:math';
import 'package:flutter/material.dart';

class ColorGenerator {
  static const List<Color> availableColors = [
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.red,
    Colors.purple,
    Colors.orange,
  ];

  static const List<String> colorNames = [
    'green',
    'blue',
    'yellow',
    'red',
    'purple',
    'orange',
  ];

  /// 随机分配一个颜色
  static String assignRandomColor() {
    final random = Random();
    return colorNames[random.nextInt(colorNames.length)];
  }

  /// 根据颜色名称获取Color对象
  static Color getColorByName(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// 根据颜色名称获取中文名称
  static String getChineseName(String colorName) {
    switch (colorName) {
      case 'green':
        return '绿色';
      case 'blue':
        return '蓝色';
      case 'yellow':
        return '黄色';
      case 'red':
        return '红色';
      case 'purple':
        return '紫色';
      case 'orange':
        return '橙色';
      default:
        return '未知';
    }
  }

  /// 根据颜色名称获取Emoji
  static String getColorEmoji(String colorName) {
    switch (colorName) {
      case 'green':
        return '🟢';
      case 'blue':
        return '🔵';
      case 'yellow':
        return '🟡';
      case 'red':
        return '🔴';
      case 'purple':
        return '🟣';
      case 'orange':
        return '🟠';
      default:
        return '⚪';
    }
  }
}
