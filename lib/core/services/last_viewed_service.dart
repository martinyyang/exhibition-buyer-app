import 'package:shared_preferences/shared_preferences.dart';

/// 管理照片最后查看时间的服务
class LastViewedService {
  static const String _keyPrefix = 'photo_last_viewed_';

  final SharedPreferences _prefs;

  LastViewedService(this._prefs);

  /// 记录用户查看照片的时间
  Future<void> markPhotoAsViewed(String photoId) async {
    final key = '$_keyPrefix$photoId';
    await _prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// 获取用户最后查看照片的时间
  DateTime? getLastViewedTime(String photoId) {
    final key = '$_keyPrefix$photoId';
    final timeString = _prefs.getString(key);
    if (timeString == null) return null;

    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  /// 清除照片的查看记录（可选，用于测试或清理）
  Future<void> clearPhotoViewedTime(String photoId) async {
    final key = '$_keyPrefix$photoId';
    await _prefs.remove(key);
  }
}
