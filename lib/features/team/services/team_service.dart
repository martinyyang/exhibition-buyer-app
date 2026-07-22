import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/team.dart';
import '../../auth/models/user.dart';

class TeamService {
  final SupabaseClient _supabase;

  TeamService(this._supabase);

  /// 创建新小组
  Future<Team> createTeam({required String name}) async {
    final teamData = {'name': name};

    final result = await _supabase
        .from('teams')
        .insert(teamData)
        .select()
        .single();

    return Team.fromJson(result);
  }

  /// 获取小组信息
  Future<Team?> getTeam(String teamId) async {
    final result = await _supabase
        .from('teams')
        .select()
        .eq('id', teamId)
        .maybeSingle();

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
    await _supabase
        .from('users')
        .update({'team_id': teamId})
        .eq('id', userId);
  }

  /// 从小组移除成员
  Future<void> removeMember({required String userId}) async {
    await _supabase
        .from('users')
        .update({'team_id': null})
        .eq('id', userId);
  }

  /// 获取小组所有成员
  Future<List<User>> getTeamMembers(String teamId) async {
    final result = await _supabase
        .from('users')
        .select()
        .eq('team_id', teamId)
        .order('created_at', ascending: true);

    return (result as List).map((json) => User.fromJson(json)).toList();
  }

  /// 更新用户最后活跃时间（用于在线状态）
  Future<void> updateLastSeen(String userId) async {
    await _supabase
        .from('users')
        .update({'last_seen': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }
}
