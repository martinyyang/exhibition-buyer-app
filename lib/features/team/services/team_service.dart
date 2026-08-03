import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/team.dart';
import '../../auth/models/user.dart' as models;

class TeamService {
  final SupabaseClient _supabase;

  TeamService(this._supabase);

  /// 创建新小组
  Future<Team> createTeam(
      {required String name, required String password}) async {
    if (password.isEmpty) {
      throw Exception('Password is required');
    }

    final teamData = {
      'name': name,
      'password': password,
    };

    final result =
        await _supabase.from('teams').insert(teamData).select().single();

    return Team.fromJson(result);
  }

  /// 通过团队名或邀请码 + 密码加入团队
  Future<Team> joinTeamByIdentifierAndPassword({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();
    final cleanPassword = password.trim();

    if (cleanIdentifier.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Team identifier and password cannot be empty');
    }

    final allTeamsResult = await _supabase.from('teams').select();
    final allTeams =
        (allTeamsResult as List).map((json) => Team.fromJson(json)).toList();

    // 检查是否是 6 位邀请码（全大写字母/数字）
    final isInviteCode = cleanIdentifier.length == 6 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(cleanIdentifier.toUpperCase());

    if (isInviteCode) {
      // 按邀请码查找
      for (final team in allTeams) {
        if (team.inviteCode.toUpperCase() == cleanIdentifier.toUpperCase()) {
          // 验证密码
          if (team.password == cleanPassword) {
            return team;
          } else {
            throw Exception('Incorrect password for this team');
          }
        }
      }
      throw Exception('Team not found with this invite code');
    } else {
      // 按团队名查找
      final matchingTeams = allTeams
          .where((team) =>
              team.name.trim().toLowerCase() == cleanIdentifier.toLowerCase())
          .toList();

      if (matchingTeams.isEmpty) {
        throw Exception('Team not found with this name');
      }

      // 找到匹配密码的团队
      for (final team in matchingTeams) {
        if (team.password == cleanPassword) {
          return team;
        }
      }

      throw Exception('Incorrect password for this team');
    }
  }

  /// 验证团队密码并返回团队信息（用于查看邀请码）
  Future<Team?> verifyTeamPassword({
    required String teamId,
    required String password,
  }) async {
    final result = await _supabase
        .from('teams')
        .select()
        .eq('id', teamId)
        .eq('password', password)
        .maybeSingle();

    if (result == null) return null;
    return Team.fromJson(result);
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

  /// 兼容方法：查找并验证团队
  Future<Team> findAndVerifyTeam(
      {required String identifier, required String password}) async {
    return joinTeamByIdentifierAndPassword(
        identifier: identifier, password: password);
  }

  /// 兼容方法：通过邀请码或名称加入团队
  Future<Team> joinTeamByInviteCodeOrName(String identifier,
      {String password = ''}) async {
    return joinTeamByIdentifierAndPassword(
        identifier: identifier, password: password);
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
