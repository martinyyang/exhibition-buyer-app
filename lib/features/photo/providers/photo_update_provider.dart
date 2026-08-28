import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../flag/providers/flag_provider.dart';
import '../../../core/providers/last_viewed_provider.dart';

/// 检查照片是否有新的旗子更新
///
/// 逻辑：
/// 1. 轻量查询该照片最新一次旗子更新时间（不订阅 Realtime）
/// 2. 与用户最后查看时间对比
/// 3. 如果最新更新时间 > 最后查看时间，返回 true（显示红点）
///
/// 采用一次性查询而非订阅 flagsProvider，避免照片网格页
/// 为每张照片维持大量旗子 Realtime 订阅；实时更新在详情页生效。
final photoHasUpdatesProvider =
    FutureProvider.family<bool, String>((ref, photoId) async {
  final flagService = ref.watch(flagServiceProvider);

  // 1. 轻量查询该照片最新一次旗子更新时间
  final latestUpdate = await flagService.getLatestFlagUpdatedAt(photoId);

  // 如果没有旗子，不显示更新提醒
  if (latestUpdate == null) {
    return false;
  }

  // 2. 获取用户最后查看时间
  final lastViewedService = ref.watch(lastViewedServiceProvider);
  final lastViewedTime = lastViewedService.getLastViewedTime(photoId);

  // 3. 如果从未查看过，不显示红点（第一次看到这张照片）
  if (lastViewedTime == null) {
    return false;
  }

  return latestUpdate.isAfter(lastViewedTime);
});
