/// 网络配置常量
/// 针对中国网络环境优化的超时和重试设置
class NetworkConfig {
  // 基础超时设置（针对中国网络环境适当延长）
  static const Duration shortTimeout = Duration(seconds: 10); // 查询操作
  static const Duration mediumTimeout = Duration(seconds: 20); // 上传操作
  static const Duration longTimeout = Duration(seconds: 30); // 大文件上传

  // Realtime连接超时
  static const Duration realtimeConnectTimeout = Duration(seconds: 15);
  static const Duration realtimeHeartbeatInterval = Duration(seconds: 30);

  // 重试配置
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // 图片压缩配置
  static const int imageQuality = 85; // 压缩质量 (0-100)
  static const int maxImageWidth = 1920; // 最大宽度
  static const int maxImageHeight = 1920; // 最大高度
  static const int thumbnailSize = 400; // 缩略图尺寸

  // 网络检测
  static const Duration networkCheckInterval = Duration(seconds: 5);
}
