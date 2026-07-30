import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/team.dart';
import '../../auth/models/user.dart' as models;

class TeamService {
  final SupabaseClient _supabase;

  TeamService(this._supabase);

  /// 创建新小组
  Future<Team> createTeam({required String name}) async {
    final teamData = {'name': name};

    final result =
        await _supabase.from('teams').insert(teamData).select().single();

    return Team.fromJson(result);
  }

  /// 智能查找或创建小组：若已存在同名小组则直接加入，否则创建新小组
  Future<Team> getOrCreateTeamByName({required String name}) async {
    final trimmedName = name.trim();
    final existingTeam = await _supabase
        .from('teams')
        .select()
        .eq('name', trimmedName)
        .maybeSingle();

    if (existingTeam != null) {
      return Team.fromJson(existingTeam);
    }

    return await createTeam(name: trimmedName);
  }

  /// 获取小组信息
  Future<Team?> getTeam(String teamId) async {
    final result =
        await _supabase.from('teams').select().eq('id', teamId).maybeSingle();

    if (result == null) return null;
    return Team.fromJson(result);
  }

  /// 更新小组信息
  Future<Team> updateTeam({
    required String teamId,
    required String name,
  }) async {
    final updateData = {'name': name};

    final result = await _supabase
        .from('teams')
        .update(updateData)
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromJson(result);
  }

  /// 添加成员到小组
  Future<void> addMember({
    required String userId,
    required String teamId,
  }) async {
    await _supabase.from('users').update({'team_id': teamId}).eq('id', userId);
  }

  /// 从小组移除成员
  Future<void> removeMember({required String userId}) async {
    await _supabase.from('users').update({'team_id': null}).eq('id', userId);
  }

  /// 获取小组所有成员
  Future<List<models.User>> getTeamMembers(String teamId) async {
    final result = await _supabase
        .from('users')
        .select()
        .eq('team_id', teamId)
        .order('created_at', ascending: true);

    return (result as List).map((json) => models.User.fromJson(json)).toList();
  }

  /// 更新用户最后活跃时间（用于在线状态）
  Future<void> updateLastSeen(String userId) async {
    await _supabase.from('users').update(
        {'last_seen': DateTime.now().toIso8601String()}).eq('id', userId);
  }

  /// 更新用户的团队ID
  Future<void> updateUserTeam(String userId, String teamId) async {
    await _supabase.from('users').update({'team_id': teamId}).eq('id', userId);
  }

  /// 获取所有团队列表
  Future<List<Team>> getAllTeams() async {
    final result = await _supabase
        .from('teams')
        .select()
        .order('created_at', ascending: false);

    return (result as List).map((json) => Team.fromJson(json)).toList();
  }
}
