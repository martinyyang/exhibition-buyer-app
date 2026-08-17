import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/team.dart';
import '../../auth/models/user.dart' as models;

class TeamService {
  final SupabaseClient _supabase;

  /// teams 表可安全 SELECT 的列（不含 password，配合 RLS 列级权限）
  static const String _teamSelectColumns = 'id,name,created_at,creator_id';

  TeamService(this._supabase);

  /// 创建新小组（服务端 RPC：创建 + 设置创建者 + 自动加入，原子操作）
  Future<Team> createTeam({
    required String name,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw Exception('Password is required');
    }

    final result = await _supabase.rpc('create_team', params: {
      'p_name': name.trim(),
      'p_password': password.trim(),
    });

    if (result == null || (result is List && result.isEmpty)) {
      throw Exception('Failed to create team');
    }

    final teamData = result is List ? result.first : result;
    return Team.fromJson(teamData);
  }

  /// 通过团队名或邀请码 + 密码加入团队
  /// 服务端 RPC（join_team）会验证密码并原子地设置当前用户的 team_id
  Future<Team> joinTeamByIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();
    final cleanPassword = password.trim();

    if (cleanIdentifier.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Team identifier and password cannot be empty');
    }

    final result = await _supabase.rpc('join_team', params: {
      'p_identifier': cleanIdentifier,
      'p_password': cleanPassword,
    });

    if (result == null || (result is List && result.isEmpty)) {
      throw Exception('Team not found or incorrect password');
    }

    // RPC 返回数组，取第一个元素
    final teamData = result is List ? result.first : result;
    return Team.fromJson(teamData);
  }

  /// 验证团队密码并返回团队信息（用于查看邀请码）
  Future<Team?> verifyTeamPassword({
    required String teamId,
    required String password,
  }) async {
    try {
      // 调用数据库函数在服务端验证密码
      final result = await _supabase.rpc('get_team_with_password', params: {
        'p_team_id': teamId,
        'p_password': password.trim(),
      });

      if (result == null || (result is List && result.isEmpty)) {
        return null;
      }

      // 数据库函数返回数组，取第一个元素
      final teamData = result is List ? result.first : result;
      return Team.fromJson(teamData);
    } catch (e) {
      return null;
    }
  }

  /// 获取小组信息（仅非敏感列）
  Future<Team?> getTeam(String teamId) async {
    final result = await _supabase
        .from('teams')
        .select(_teamSelectColumns)
        .eq('id', teamId)
        .maybeSingle();

    if (result == null) return null;
    return Team.fromJson(result);
  }

  /// 更新小组名称
  Future<Team> updateTeam({
    required String teamId,
    required String name,
  }) async {
    final updateData = {'name': name};

    final result = await _supabase
        .from('teams')
        .update(updateData)
        .eq('id', teamId)
        .select(_teamSelectColumns)
        .single();

    return Team.fromJson(result);
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

  /// 兼容方法：查找并验证团队（加入团队，会设置当前用户的 team_id）
  Future<Team> findAndVerifyTeam(
      {required String identifier, required String password}) async {
    return joinTeamByIdentifierAndPassword(
        identifier: identifier, password: password);
  }

  /// 兼容方法：通过邀请码或名称加入团队（会设置当前用户的 team_id）
  Future<Team> joinTeamByInviteCodeOrName(String identifier,
      {String password = ''}) async {
    return joinTeamByIdentifierAndPassword(
        identifier: identifier, password: password);
  }
}
