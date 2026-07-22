import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../../../core/utils/color_generator.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// 获取当前用户ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// 检查用户是否已登录
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// 用户登录
  Future<models.User> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('登录失败');
    }

    // 获取用户详细信息
    final userDoc = await _supabase
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .single();

    final user = models.User.fromJson(userDoc);

    // 如果是买手，分配每日颜色
    if (user.isBuyer) {
      await _assignDailyColorIfNeeded(user);
    }

    return user;
  }

  /// 用户注册
  Future<models.User> signUp({
    required String email,
    required String password,
    required String role,
    String? teamId,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('注册失败');
    }

    // 创建用户记录
    final userData = {
      'id': response.user!.id,
      'email': email,
      'role': role,
      'team_id': teamId,
    };

    await _supabase.from('users').insert(userData);

    final userDoc = await _supabase
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .single();

    final user = models.User.fromJson(userDoc);

    // 如果是买手，分配每日颜色
    if (user.isBuyer) {
      await _assignDailyColorIfNeeded(user);
    }

    return user;
  }

  /// 登出
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 获取当前用户信息
  Future<models.User?> getCurrentUser() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    final userDoc = await _supabase
        .from('users')
        .select()
        .eq('id', currentUser.id)
        .maybeSingle();

    if (userDoc == null) return null;

    final user = models.User.fromJson(userDoc);

    // 如果是买手，检查并分配每日颜色
    if (user.isBuyer) {
      await _assignDailyColorIfNeeded(user);
      // 重新获取更新后的用户信息
      final updatedDoc = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();
      return models.User.fromJson(updatedDoc);
    }

    return user;
  }

  /// 分配每日颜色（如果需要）
  Future<void> _assignDailyColorIfNeeded(models.User user) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // 如果今天已分配颜色，直接返回
    if (user.colorAssignedDate != null) {
      final assignedDate = user.colorAssignedDate!.toIso8601String().split('T')[0];
      if (assignedDate == today) {
        return;
      }
    }

    // 否则随机分配新颜色
    final randomColor = ColorGenerator.assignRandomColor();

    await _supabase.from('users').update({
      'daily_color': randomColor,
      'color_assigned_date': today,
    }).eq('id', user.id);
  }

  /// 监听认证状态变化
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
