import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'image_helper_interface.dart';

/// 移动端图片处理服务实现
///
/// 使用 dart:io File 和 path_provider 进行文件操作
/// 支持相机和相册选择
class ImageHelperMobile implements ImageHelperInterface {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      // 选择照片
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
  Future<XFile?> compressImage(XFile file, {int quality = 85}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/${timestamp}_compressed.jpg';

      // 尝试指定质量压缩
      var result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result == null) {
        throw Exception('Compression failed');
      }

      File compressedFile = File(result.path);

      // 检查文件大小，如果超过2MB，降低质量重新压缩
      int fileSize = await compressedFile.length();
      const maxSize = 2 * 1024 * 1024; // 2MB

      if (fileSize > maxSize) {
        // 重新压缩，质量降至70%
        result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          '${tempDir.path}/${timestamp}_compressed_70.jpg',
          quality: 70,
          minWidth: 1920,
          minHeight: 1080,
        );

        if (result == null) {
          throw Exception('Second compression failed');
        }

        compressedFile = File(result.path);
        fileSize = await compressedFile.length();

        // 如果还是太大，进一步降低质量和尺寸
        if (fileSize > maxSize) {
          result = await FlutterImageCompress.compressAndGetFile(
            file.path,
            '${tempDir.path}/${timestamp}_compressed_50.jpg',
            quality: 50,
            minWidth: 1280,
            minHeight: 720,
          );

          if (result == null) {
            throw Exception('Final compression failed');
          }

          compressedFile = File(result.path);
        }
      }

      return XFile(compressedFile.path);
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }
}
