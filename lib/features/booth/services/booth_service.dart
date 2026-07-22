import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booth.dart';

class BoothService {
  final SupabaseClient _supabase;

  BoothService(this._supabase);

  /// 创建新摊位
  Future<Booth> createBooth({
    required String boothNumber,
    required String eventId,
    required String teamId,
    required String createdBy,
  }) async {
    final boothData = {
      'booth_number': boothNumber,
      'event_id': eventId,
      'team_id': teamId,
      'created_by': createdBy,
    };

    final result = await _supabase
        .from('booths')
        .insert(boothData)
        .select()
        .single();

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
        .order('created_at', ascending: false);

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
    final result = await _supabase
        .from('booths')
        .select()
        .eq('id', boothId)
        .single();

    return Booth.fromJson(result);
  }

  /// 更新摊位信息
  Future<Booth> updateBooth({
    required String boothId,
    String? boothNumber,
  }) async {
    final updateData = <String, dynamic>{};
    if (boothNumber != null) updateData['booth_number'] = boothNumber;

    final result = await _supabase
        .from('booths')
        .update(updateData)
        .eq('id', boothId)
        .select()
        .single();

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
}
