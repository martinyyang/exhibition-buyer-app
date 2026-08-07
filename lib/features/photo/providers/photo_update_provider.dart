import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../flag/providers/flag_provider.dart';
import '../../../core/providers/last_viewed_provider.dart';

/// 检查照片是否有新的旗子更新
///
/// 逻辑：
/// 1. 获取该照片的所有旗子
/// 2. 找到最新的 updatedAt 时间
/// 3. 与用户最后查看时间对比
/// 4. 如果最新更新时间 > 最后查看时间，返回 true（显示红点）
final photoHasUpdatesProvider =
    FutureProvider.family<bool, String>((ref, photoId) async {
  // 1. 获取该照片的所有旗子
  final flagsAsync = await ref.watch(flagsProvider(photoId).future);

  // 如果没有旗子，不显示更新提醒
  if (flagsAsync.isEmpty) {
    return false;
  }

  // 2. 找到最新的 updatedAt 时间
  final latestUpdate = flagsAsync
      .map((flag) => flag.updatedAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  // 3. 获取用户最后查看时间
  final lastViewedService = ref.watch(lastViewedServiceProvider);
  final lastViewedTime = lastViewedService.getLastViewedTime(photoId);

  // 4. 如果从未查看过，或者有新更新，返回 true
  if (lastViewedTime == null) {
    return false; // 第一次看到这张照片，不显示红点
  }

  return latestUpdate.isAfter(lastViewedTime);
});
