import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/team_service.dart';
import '../../auth/models/team.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';

// TeamService Provider
final teamServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return TeamService(supabase.client);
});

// 当前用户的小组信息Provider
final currentTeamProvider = FutureProvider<Team?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final teamService = ref.watch(teamServiceProvider);

  final user = await authService.getCurrentUser();
  if (user?.teamId == null) return null;

  return await teamService.getTeam(user!.teamId!);
});

// 小组成员列表Provider（包含买手颜色标识）
final teamMembersProvider = FutureProvider<List<User>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final teamService = ref.watch(teamServiceProvider);

  final user = await authService.getCurrentUser();
  if (user?.teamId == null) return [];

  return await teamService.getTeamMembers(user!.teamId!);
});

// 特定小组的成员Provider（用于按teamId查询）
final teamMembersByIdProvider = FutureProvider.family<List<User>, String>((ref, teamId) async {
  final teamService = ref.watch(teamServiceProvider);
  return await teamService.getTeamMembers(teamId);
});

// 在线成员Provider（过滤出在线的买手）
final onlineMembersProvider = FutureProvider<List<User>>((ref) async {
  final members = await ref.watch(teamMembersProvider.future);
  return members.where((user) => user.isOnline).toList();
});

// 在线成员数量Provider
final onlineMembersCountProvider = FutureProvider<int>((ref) async {
  final onlineMembers = await ref.watch(onlineMembersProvider.future);
  return onlineMembers.length;
});
