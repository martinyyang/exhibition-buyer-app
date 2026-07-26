import 'package:flutter/foundation.dart' show kIsWeb;
import 'image_helper_interface.dart';
import 'image_helper_mobile.dart';
import 'image_helper_web.dart';

/// 获取平台对应的图片处理服务实现
///
/// 根据当前运行平台返回对应的实现：
/// - Web: ImageHelperWeb
/// - Mobile/Desktop: ImageHelperMobile
ImageHelperInterface getImageHelper() {
  if (kIsWeb) {
    return ImageHelperWeb();
  } else {
    return ImageHelperMobile();
  }
}

/// 全局单例图片处理服务
///
/// 使用示例：
/// ```dart
/// final file = await imageHelper.pickImage(source: ImageSource.gallery);
/// if (file != null) {
///   final compressed = await imageHelper.compressImage(file);
/// }
/// ```
final imageHelper = getImageHelper();
