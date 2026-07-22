import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// 图片选择和压缩辅助服务
/// 处理照片选择、拍照、压缩等功能
class ImageHelperService {
  final ImagePicker _picker = ImagePicker();

  /// 从相册选择照片并压缩
  Future<File?> pickFromGallery() async {
    return _pickAndCompress(ImageSource.gallery);
  }

  /// 拍照并压缩
  Future<File?> pickFromCamera() async {
    return _pickAndCompress(ImageSource.camera);
  }

  /// 选择照片并压缩（内部方法）
  Future<File?> _pickAndCompress(ImageSource source) async {
    try {
      // 选择照片
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920, // 预先限制宽度
        imageQuality: 85, // 预先设置质量
      );

      if (pickedFile == null) return null;

      // 进一步压缩照片（确保不超过2MB）
      final compressedFile = await compressImage(File(pickedFile.path));

      return compressedFile;
    } catch (e) {
      throw Exception('Failed to pick and compress image: $e');
    }
  }

  /// 压缩图片文件
  /// 质量85%，最大宽度1920px，确保文件大小在2MB以内
  Future<File?> compressImage(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/${timestamp}_compressed.jpg';

      // 尝试质量85%压缩
      var result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 85,
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
          imageFile.path,
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
            imageFile.path,
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

      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// 检查图片文件大小（字节）
  Future<int> getImageSize(File imageFile) async {
    return await imageFile.length();
  }

  /// 检查图片是否超过指定大小（MB）
  Future<bool> isImageTooLarge(File imageFile, {double maxSizeMB = 2.0}) async {
    final size = await getImageSize(imageFile);
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return size > maxSizeBytes;
  }
}
