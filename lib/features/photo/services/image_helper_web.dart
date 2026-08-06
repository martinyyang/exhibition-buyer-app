import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'image_helper_interface.dart';

/// Web 端图片处理服务实现
///
/// 使用 XFile 在内存中处理，避免文件系统依赖
/// 支持文件选择器和移动端相机调用
class ImageHelperWeb implements ImageHelperInterface {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      // Web 端支持传入 source 参数，移动浏览器可以调用相机
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // 压缩照片
      return await compressImage(pickedFile);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  @override
  Future<List<XFile>> pickMultipleImages() async {
    try {
      // Web 端支持多选文件
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return [];

      // 批量压缩照片
      final List<XFile> compressedFiles = [];
      for (final file in pickedFiles) {
        final compressed = await compressImage(file);
        if (compressed != null) {
          compressedFiles.add(compressed);
        }
      }

      return compressedFiles;
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  @override
  Future<XFile?> compressImage(XFile file, {int quality = 85}) async {
    try {
      // Web 端在内存中压缩，使用 Uint8List
      final bytes = await file.readAsBytes();

      // 尝试指定质量压缩
      var result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: 1920,
        minHeight: 1080,
      );

      // 检查文件大小，如果超过2MB，降低质量重新压缩
      const maxSize = 2 * 1024 * 1024; // 2MB

      if (result.length > maxSize) {
        // 重新压缩，质量降至70%
        result = await FlutterImageCompress.compressWithList(
          bytes,
          quality: 70,
          minWidth: 1920,
          minHeight: 1080,
        );

        // 如果还是太大，进一步降低质量和尺寸
        if (result.length > maxSize) {
          result = await FlutterImageCompress.compressWithList(
            bytes,
            quality: 50,
            minWidth: 1280,
            minHeight: 720,
          );
        }
      }

      // 返回新的 XFile（内存中）
      return XFile.fromData(
        result,
        name: file.name,
        mimeType: file.mimeType ?? 'image/jpeg',
        length: result.length,
      );
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }
}
