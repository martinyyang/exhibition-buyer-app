import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/photo.dart';

class PhotoService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  PhotoService(this._supabase);

  /// 上传照片并创建记录
  Future<Photo> uploadPhoto({
    required File photoFile,
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

    // 上传到Supabase Storage
    await _supabase.storage.from('photos').upload(
          filePath,
          photoFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    // 获取公共URL
    final publicUrl = _supabase.storage
        .from('photos')
        .getPublicUrl(filePath);

    // 创建照片记录
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
        .single();

    return Photo.fromJson(result);
  }

  /// 获取摊位的所有照片
  Future<List<Photo>> getPhotos(String boothId) async {
    final result = await _supabase
        .from('photos')
        .select()
        .eq('booth_id', boothId)
        .order('created_at', ascending: false);

    return (result as List).map((json) => Photo.fromJson(json)).toList();
  }

  /// 获取单张照片详情
  Future<Photo?> getPhoto(String photoId) async {
    try {
      final result = await _supabase
          .from('photos')
          .select()
          .eq('id', photoId)
          .single();

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
    if (supplierName != null) updateData['supplier_name'] = supplierName;
    if (supplierLogoUrl != null) updateData['supplier_logo_url'] = supplierLogoUrl;

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
  Future<String> uploadSupplierLogo(File logoFile) async {
    // 生成唯一文件名：suppliers/{timestamp}_{uuid}.jpg
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4();
    final fileName = '${timestamp}_$uuid.jpg';
    final filePath = 'suppliers/$fileName';

    // 上传到Supabase Storage
    await _supabase.storage.from('photos').upload(
          filePath,
          logoFile,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    // 获取公共URL
    final publicUrl = _supabase.storage
        .from('photos')
        .getPublicUrl(filePath);

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

  /// 从image_picker选择并压缩照片（可选功能，需要image_picker和flutter_image_compress）
  /// 这个方法可以在UI层调用，然后将压缩后的文件传给uploadPhoto
  /// 示例实现在PhotoService中作为工具方法提供
  /*
  Future<File?> pickAndCompressPhoto({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return null;

    // 压缩照片
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      quality: 85,
      minWidth: 1920,
      minHeight: 1080,
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }
  */
}

