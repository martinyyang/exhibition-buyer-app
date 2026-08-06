import 'dart:math';
import '../models/flag.dart';

/// 旗子分组信息
class FlagGroup {
  final double centerX;
  final double centerY;
  final List<Flag> flags;

  FlagGroup({
    required this.centerX,
    required this.centerY,
    required this.flags,
  });
}

/// 旗子布局位置
class FlagPosition {
  final Flag flag;
  final double x;
  final double y;
  final bool isGrouped; // 是否属于多旗子组
  final int groupSize; // 所在组的旗子数量

  FlagPosition({
    required this.flag,
    required this.x,
    required this.y,
    this.isGrouped = false,
    this.groupSize = 1,
  });
}

/// 旗子布局辅助类，处理重叠检测和自动展开
class FlagLayoutHelper {
  /// 重叠阈值：两个旗子的坐标距离小于此值时视为重叠（相对于图片宽度的百分比）
  static const double overlapThreshold = 0.05;

  /// 展开半径：重叠旗子的环形展开半径（相对于图片宽度的百分比）
  static const double spreadRadius = 0.08;

  /// 计算两个旗子之间的距离
  static double _distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  /// 将旗子分组（相邻的旗子归为一组）
  static List<FlagGroup> _groupFlags(List<Flag> flags) {
    if (flags.isEmpty) return [];

    final groups = <FlagGroup>[];
    final processed = <String>{};

    for (final flag in flags) {
      if (processed.contains(flag.id)) continue;

      // 查找与当前旗子重叠的所有旗子
      final group = <Flag>[flag];
      processed.add(flag.id);

      for (final other in flags) {
        if (processed.contains(other.id)) continue;

        // 计算与组中任意旗子的最小距离
        final minDistance = group.map((f) {
          return _distance(
              f.positionX, f.positionY, other.positionX, other.positionY);
        }).reduce(min);

        if (minDistance < overlapThreshold) {
          group.add(other);
          processed.add(other.id);
        }
      }

      // 计算组的中心点（所有旗子的平均位置）
      final centerX =
          group.map((f) => f.positionX).reduce((a, b) => a + b) / group.length;
      final centerY =
          group.map((f) => f.positionY).reduce((a, b) => a + b) / group.length;

      groups.add(FlagGroup(
        centerX: centerX,
        centerY: centerY,
        flags: group,
      ));
    }

    return groups;
  }

  /// 计算旗子的展开布局位置
  static List<FlagPosition> calculateLayout(List<Flag> flags) {
    final groups = _groupFlags(flags);
    final positions = <FlagPosition>[];

    for (final group in groups) {
      if (group.flags.length == 1) {
        // 单个旗子，直接使用原始位置
        final flag = group.flags.first;
        positions.add(FlagPosition(
          flag: flag,
          x: flag.positionX,
          y: flag.positionY,
          isGrouped: false,
          groupSize: 1,
        ));
      } else {
        // 多个旗子，环形展开
        final angleStep = 2 * pi / group.flags.length;

        for (int i = 0; i < group.flags.length; i++) {
          final angle = i * angleStep - pi / 2; // 从顶部开始（-90度）
          final offsetX = cos(angle) * spreadRadius;
          final offsetY = sin(angle) * spreadRadius;

          positions.add(FlagPosition(
            flag: group.flags[i],
            x: (group.centerX + offsetX).clamp(0.0, 1.0),
            y: (group.centerY + offsetY).clamp(0.0, 1.0),
            isGrouped: true,
            groupSize: group.flags.length,
          ));
        }
      }
    }

    return positions;
  }

  /// 获取旗子组的信息（用于显示聚合指示器）
  static Map<String, FlagGroup> getGroupInfo(List<Flag> flags) {
    final groups = _groupFlags(flags);
    final groupMap = <String, FlagGroup>{};

    for (final group in groups) {
      if (group.flags.length > 1) {
        // 只记录多旗子组
        for (final flag in group.flags) {
          groupMap[flag.id] = group;
        }
      }
    }

    return groupMap;
  }
}
