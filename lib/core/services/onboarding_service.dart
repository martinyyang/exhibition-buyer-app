import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _prefix = 'onboarding_seen_';

  /// 检查用户是否已经看过特定页面的导引
  Future<bool> hasSeenOnboarding(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$pageKey') ?? false;
  }

  /// 标记用户已经看过特定页面的导引
  Future<void> markOnboardingSeen(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$pageKey', true);
  }

  /// 重置所有导引状态（用于测试或重置功能）
  Future<void> resetAllOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// 重置特定页面的导引状态
  Future<void> resetOnboarding(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$pageKey');
  }
}
