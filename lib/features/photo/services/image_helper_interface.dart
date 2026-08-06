import 'package:image_picker/image_picker.dart';

/// 图片处理服务的平台抽象接口
///
/// 提供跨平台的图片选择和压缩功能
/// - Mobile: 支持相机和相册
/// - Web: 仅支持文件选择器
abstract class ImageHelperInterface {
  /// 选择图片
  ///
  /// [source] 图片来源 (相机或相册)
  /// Web 端会忽略 source 参数，始终使用文件选择器
  Future<XFile?> pickImage({required ImageSource source});

  /// 批量选择图片
  ///
  /// 仅支持相册选择（相机不支持批量）
  /// Web 端支持多选文件
  Future<List<XFile>> pickMultipleImages();

  /// 压缩图片
  ///
  /// [file] 要压缩的图片文件
  /// [quality] 压缩质量 (0-100)
  ///
  /// Mobile: 使用文件系统临时存储
  /// Web: 在内存中处理
  Future<XFile?> compressImage(XFile file, {int quality = 85});
}
