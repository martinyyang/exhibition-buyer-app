import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booth.dart';
import '../../../core/config/network_config.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class BoothService {
  final SupabaseClient _supabase;

  BoothService(this._supabase);

  /// 生成下一个摊位编号（格式：001, 002, 003...）
  Future<String> generateNextBoothNumber({
    required String eventId,
    required String teamId,
  }) async {
    final booths = await getBooths(eventId: eventId, teamId: teamId);

    // 获取所有纯数字的编号
    final numbers = booths
        .map((b) => int.tryParse(b.boothNumber))
        .where((n) => n != null)
        .cast<int>()
        .toList();

    final nextNumber =
        numbers.isEmpty ? 1 : (numbers.reduce((a, b) => a > b ? a : b) + 1);
    return nextNumber.toString().padLeft(3, '0');
  }

  /// 创建新摊位
  Future<Booth> createBooth({
    required String boothNumber,
    required String eventId,
    required String teamId,
    required String createdBy,
    String? coverImageUrl,
  }) async {
    final boothData = {
      'booth_number': boothNumber,
      'event_id': eventId,
      'team_id': teamId,
      'created_by': createdBy,
      if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
    };

    final result = await _supabase
        .from('booths')
        .insert(boothData)
        .select()
        .single()
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('创建摊位超时'),
        );

    return Booth.fromJson(result);
  }

  /// 获取场次下的所有摊位（需同时过滤teamId实现数据隔离）
  Future<List<Booth>> getBooths({
    required String eventId,
    required String teamId,
  }) async {
    final result = await _supabase
        .from('booths')
        .select()
        .eq('event_id', eventId)
        .eq('team_id', teamId)
        .order('created_at', ascending: false)
        .timeout(
          NetworkConfig.shortTimeout,
          onTimeout: () => throw Exception('获取摊位列表超时'),
        );

    return (result as List).map((json) => Booth.fromJson(json)).toList();
  }

  /// 获取场次下的所有摊位（已废弃，使用getBooths替代）
  @Deprecated('Use getBooths with teamId parameter for data isolation')
  Future<List<Booth>> getBoothsByEvent(String eventId) async {
    final result = await _supabase
        .from('booths')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (result as List).map((json) => Booth.fromJson(json)).toList();
  }

  /// 获取团队的所有摊位（跨场次）
  Future<List<Booth>> getBoothsByTeam(String teamId) async {
    final result = await _supabase
        .from('booths')
        .select()
        .eq('team_id', teamId)
        .order('created_at', ascending: false);

    return (result as List).map((json) => Booth.fromJson(json)).toList();
  }

  /// 获取单个摊位详情
  Future<Booth> getBooth(String boothId) async {
    final result =
        await _supabase.from('booths').select().eq('id', boothId).single();

    return Booth.fromJson(result);
  }

  /// 更新摊位信息
  Future<Booth> updateBooth({
    required String boothId,
    String? boothNumber,
    String? coverImageUrl,
  }) async {
    final updateData = <String, dynamic>{};
    if (boothNumber != null) updateData['booth_number'] = boothNumber;
    if (coverImageUrl != null) updateData['cover_image_url'] = coverImageUrl;

    // 执行更新（不要在 URL 中使用 select）
    await _supabase.from('booths').update(updateData).eq('id', boothId);

    // 单独查询更新后的数据
    final result =
        await _supabase.from('booths').select().eq('id', boothId).single();

    return Booth.fromJson(result);
  }

  /// 删除摊位
  Future<void> deleteBooth(String boothId) async {
    await _supabase.from('booths').delete().eq('id', boothId);
  }

  /// 检查摊位号是否存在（同一场次内）
  Future<bool> boothNumberExists({
    required String eventId,
    required String boothNumber,
  }) async {
    final result = await _supabase
        .from('booths')
        .select()
        .eq('event_id', eventId)
        .eq('booth_number', boothNumber)
        .maybeSingle();

    return result != null;
  }

  /// 上传摊位封面图片（后台异步）
  Future<String> uploadBoothCover({
    required XFile imageFile,
    required String boothId,
    required String teamId,
  }) async {
    // 压缩图片为 WebP
    final bytes = await imageFile.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 800,
      minHeight: 800,
      quality: 85,
      format: CompressFormat.webp,
    );

    // 生成文件路径：booth-covers/{team_id}/{booth_id}.webp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = 'booth-covers/$teamId/${boothId}_$timestamp.webp';

    // 上传到 Supabase Storage
    await _supabase.storage.from('photos').uploadBinary(
          filePath,
          compressedBytes,
          fileOptions: const FileOptions(
            contentType: 'image/webp',
            upsert: true,
          ),
        );

    // 返回公共URL
    return _supabase.storage.from('photos').getPublicUrl(filePath);
  }
}
