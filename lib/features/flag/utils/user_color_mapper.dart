import 'package:flutter/material.dart';

/// 用户颜色映射器，为每个用户分配固定的颜色标识
class UserColorMapper {
  /// 预定义的调色板（8种高对比度颜色，适合协作场景）
  static const List<Color> palette = [
    Color(0xFFE53935), // 红色
    Color(0xFF1E88E5), // 蓝色
    Color(0xFF43A047), // 绿色
    Color(0xFFFB8C00), // 橙色
    Color(0xFF8E24AA), // 紫色
    Color(0xFF00ACC1), // 青色
    Color(0xFFC0CA33), // 黄绿色
    Color(0xFFD81B60), // 品红色
  ];

  /// 根据用户ID获取颜色（使用哈希确保同一用户始终同一颜色）
  static Color getColorForUser(String userId) {
    final hash = userId.hashCode.abs();
    return palette[hash % palette.length];
  }

  /// 获取颜色的深色版本（用于边框或强调）
  static Color getDarkerShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withLightness((hslColor.lightness - 0.2).clamp(0.0, 1.0))
        .toColor();
  }

  /// 获取颜色的浅色版本（用于背景）
  static Color getLighterShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor
        .withLightness((hslColor.lightness + 0.3).clamp(0.0, 1.0))
        .withSaturation((hslColor.saturation * 0.3).clamp(0.0, 1.0))
        .toColor();
  }
}
