import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import '../models/photo.dart';
import '../../../core/config/network_config.dart';

class PhotoService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  PhotoService(this._supabase);

  /// 上传照片并创建记录
  ///
  /// 使用 XFile 支持跨平台（Mobile 和 Web）
  /// 自动压缩图片以优化中国网络环境下的上传速度
  Future<Photo> uploadPhoto({
    required XFile photoFile,
    required String boothId,
    required String teamId,
    required String uploadedBy,
    String? supplierName,
    String? supplierLogoUrl,
  }) async {
    // 生成唯一文件名：{team_id}/{booth_id}/{timestamp}_{uuid}.jpg
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4();
    final fileName = '${timestamp}_$uuid.jpg';
    final filePath = '$teamId/$boothId/$fileName';

    // 压缩图片以加快上传速度（针对中国网络环境优化）
    final bytes = await _compressImage(photoFile);

    // 上传到Supabase Storage
    await _supabase.storage.from('photos').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    // 获取公共URL
    final publicUrl = _supabase.storage.from('photos').getPublicUrl(filePath);

    // 创建照片记录（添加超时保护）
    final photoData = {
      'booth_id': boothId,
      'url': publicUrl,
      'supplier_name': supplierName,
      'supplier_logo_url': supplierLogoUrl,
      'uploaded_by': uploadedBy,
    };

    final result = await _supabase
        .from('photos')
        .insert(photoData)
        .select()
        .single()
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('创建照片记录超时'),
        );

    return Photo.fromJson(result);
  }

  /// 获取摊位的所有照片
  Future<List<Photo>> getPhotos(String boothId) async {
    final result = await _supabase
        .from('photos')
        .select()
        .eq('booth_id', boothId)
        .order('created_at', ascending: false)
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('获取照片列表超时'),
        );

    return (result as List).map((json) => Photo.fromJson(json)).toList();
  }

  /// 获取单张照片详情
  Future<Photo?> getPhoto(String photoId) async {
    try {
      final result =
          await _supabase.from('photos').select().eq('id', photoId).single();

      return Photo.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  /// 更新照片的供应商信息
  Future<Photo> updatePhoto({
    required String photoId,
    String? supplierName,
    String? supplierLogoUrl,
  }) async {
    final updateData = <String, dynamic>{};
    if (supplierName != null) {
      updateData['supplier_name'] = supplierName;
    }
    if (supplierLogoUrl != null) {
      updateData['supplier_logo_url'] = supplierLogoUrl;
    }

    final result = await _supabase
        .from('photos')
        .update(updateData)
        .eq('id', photoId)
        .select()
        .single();

    return Photo.fromJson(result);
  }

  /// 添加/更新照片的供应商信息
  Future<Photo> addSupplierInfo({
    required String photoId,
    required String supplierName,
    String? supplierLogoUrl,
  }) async {
    return updatePhoto(
      photoId: photoId,
      supplierName: supplierName,
      supplierLogoUrl: supplierLogoUrl,
    );
  }

  /// 删除照片
  Future<void> deletePhoto(String photoId) async {
    // 先获取照片信息以获得URL
    final photo = await getPhoto(photoId);

    if (photo == null) {
      throw Exception('Photo not found');
    }

    // 从URL提取文件路径
    final uri = Uri.parse(photo.url);
    final pathSegments = uri.pathSegments;

    // 找到存储桶后的路径部分
    // URL格式: https://xxx.supabase.co/storage/v1/object/public/photos/{team_id}/{booth_id}/{file}.jpg
    // 或: https://xxx.supabase.co/object/public/photos/{team_id}/{booth_id}/{file}.jpg
    int photosIndex = -1;
    for (int i = 0; i < pathSegments.length; i++) {
      if (pathSegments[i] == 'photos') {
        photosIndex = i;
        break;
      }
    }

    if (photosIndex == -1 || photosIndex >= pathSegments.length - 1) {
      throw Exception('Invalid photo URL format');
    }

    // 提取从'photos'之后的路径
    final filePath = pathSegments.sublist(photosIndex + 1).join('/');

    // 从Storage删除文件
    await _supabase.storage.from('photos').remove([filePath]);

    // 删除数据库记录
    await _supabase.from('photos').delete().eq('id', photoId);
  }

  /// 上传供应商Logo
  Future<String> uploadSupplierLogo(XFile logoFile) async {
    // 生成唯一文件名：suppliers/{timestamp}_{uuid}.jpg
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4();
    final fileName = '${timestamp}_$uuid.jpg';
    final filePath = 'suppliers/$fileName';

    // 压缩Logo图片
    final bytes = await _compressImage(logoFile);

    // 上传到Supabase Storage（添加超时保护）
    await _supabase.storage.from('photos').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        ).timeout(
          NetworkConfig.mediumTimeout,
          onTimeout: () => throw Exception('上传Logo超时'),
        );

    // 获取公共URL
    final publicUrl = _supabase.storage.from('photos').getPublicUrl(filePath);

    return publicUrl;
  }

  /// 获取用户上传的所有照片
  Future<List<Photo>> getPhotosByUser(String userId) async {
    final result = await _supabase
        .from('photos')
        .select()
        .eq('uploaded_by', userId)
        .order('created_at', ascending: false);

    return (result as List).map((json) => Photo.fromJson(json)).toList();
  }

  /// 压缩图片以优化上传速度
  /// 针对中国网络环境，自动压缩大图片
  Future<Uint8List> _compressImage(XFile file) async {
    try {
      // 获取原始文件大小
      final bytes = await file.readAsBytes();
      final fileSizeInMB = bytes.length / (1024 * 1024);

      // 如果文件小于1MB，直接返回原始字节
      if (fileSizeInMB < 1.0) {
        return Uint8List.fromList(bytes);
      }

      // 对于移动端，使用flutter_image_compress压缩
      if (!_isWeb()) {
        final result = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: NetworkConfig.imageQuality,
          minWidth: NetworkConfig.maxImageWidth,
          minHeight: NetworkConfig.maxImageHeight,
        );

        if (result != null) {
          return result;
        }
      }

      // Web端或压缩失败时返回原始字节
      return Uint8List.fromList(bytes);
    } catch (e) {
      // 压缩失败时返回原始字节
      final bytes = await file.readAsBytes();
      return Uint8List.fromList(bytes);
    }
  }

  /// 检测是否为Web平台
  bool _isWeb() {
    try {
      return identical(0, 0.0); // Web平台特征
    } catch (e) {
      return false;
    }
  }
}
