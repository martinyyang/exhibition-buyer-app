import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';

class EventService {
  final SupabaseClient _supabase;

  EventService(this._supabase);

  /// 创建新场次
  Future<Event> createEvent({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    required String teamId,
    bool setAsActive = true,
  }) async {
    // 如果设置为活跃场次，先将其他场次设置为非活跃
    if (setAsActive) {
      await _supabase
          .from('events')
          .update({'is_active': false})
          .eq('team_id', teamId);
    }

    final eventData = {
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'team_id': teamId,
      'is_active': setAsActive,
    };

    final result = await _supabase
        .from('events')
        .insert(eventData)
        .select()
        .single();

    return Event.fromJson(result);
  }

  /// 获取用户的所有场次（通过userId查询用户的team_id）
  Future<List<Event>> getEvents(String userId) async {
    // 先获取用户的team_id
    final userDoc = await _supabase
        .from('users')
        .select('team_id')
        .eq('id', userId)
        .single();

    final teamId = userDoc['team_id'] as String?;
    if (teamId == null) return [];

    return await getEventsByTeam(teamId);
  }

  /// 获取团队的所有场次
  Future<List<Event>> getEventsByTeam(String teamId) async {
    final result = await _supabase
        .from('events')
        .select()
        .eq('team_id', teamId)
        .order('start_date', ascending: false);

    return result.map((json) => Event.fromJson(json)).toList();
  }

  /// 获取用户的活跃场次（通过userId查询用户的team_id）
  Future<Event?> getActiveEvent(String userId) async {
    // 先获取用户的team_id
    final userDoc = await _supabase
        .from('users')
        .select('team_id')
        .eq('id', userId)
        .single();

    final teamId = userDoc['team_id'] as String?;
    if (teamId == null) return null;

    return await getActiveEventByTeam(teamId);
  }

  /// 获取团队的活跃场次
  Future<Event?> getActiveEventByTeam(String teamId) async {
    final result = await _supabase
        .from('events')
        .select()
        .eq('team_id', teamId)
        .eq('is_active', true)
        .maybeSingle();

    if (result == null) return null;
    return Event.fromJson(result);
  }

  /// 设置活跃场次
  Future<void> setActiveEvent(String eventId, String teamId) async {
    // 先将所有场次设置为非活跃
    await _supabase
        .from('events')
        .update({'is_active': false})
        .eq('team_id', teamId);

    // 设置指定场次为活跃
    await _supabase
        .from('events')
        .update({'is_active': true})
        .eq('id', eventId);
  }

  /// 更新场次信息
  Future<Event> updateEvent({
    required String eventId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (startDate != null) {
      updateData['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      updateData['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final result = await _supabase
        .from('events')
        .update(updateData)
        .eq('id', eventId)
        .select()
        .single();

    return Event.fromJson(result);
  }

  /// 删除场次
  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('events').delete().eq('id', eventId);
  }

  /// 获取单个场次详情
  Future<Event> getEvent(String eventId) async {
    final result = await _supabase
        .from('events')
        .select()
        .eq('id', eventId)
        .single();

    return Event.fromJson(result);
  }
}
