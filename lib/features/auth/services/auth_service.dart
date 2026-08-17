import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../../../core/utils/color_generator.dart';
import '../../team/services/team_service.dart';

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
      throw Exception('Login failed');
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
    try {
      print('Starting user registration for: $email');

      // 添加超时限制
      final response = await _supabase.auth
          .signUp(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Registration request timeout, please check network connection');
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed: User information not returned');
      }

      print('Auth user created: ${response.user!.id}');

      // 创建用户记录
      final userData = {
        'id': response.user!.id,
        'email': email,
        'role': role,
        'team_id': teamId,
      };

      await _supabase.from('users').insert(userData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Create user record timeout');
        },
      );

      print('User record created in database');

      final userDoc = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single()
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Get user information timeout');
        },
      );

      final user = models.User.fromJson(userDoc);

      // 如果是买手，分配每日颜色
      if (user.isBuyer) {
        await _assignDailyColorIfNeeded(user);
      }

      print('Registration completed successfully');
      return user;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// 带有重试和自愈防护的 User Profile 获取函数
  Future<models.User> _fetchUserProfileWithRetry(String userId,
      {int maxRetries = 3}) async {
    Object? lastError;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final userDoc = await _supabase
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (userDoc != null) {
          return models.User.fromJson(userDoc);
        }

        // 如果 users 表中缺少对应 uid 记录，自动进行容错修复创建
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          final newUserData = {
            'id': authUser.id,
            'email': authUser.email ?? '',
            'role': 'buyer',
          };
          await _supabase.from('users').upsert(newUserData);

          final createdDoc = await _supabase
              .from('users')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (createdDoc != null) {
            return models.User.fromJson(createdDoc);
          }
        }
      } catch (e) {
        lastError = e;
        print('Attempt $attempt to fetch user profile failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
      }
    }
    throw Exception(
        'Failed to fetch user profile after login. Please try again. ($lastError)');
  }

  /// 发送密码重置邮件
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://exhibition-buyer-app.pages.dev/reset-password',
    );
  }

  /// 更新密码（在重置流程中使用）
  Future<void> updatePassword(String newPassword) async {
    final response = await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    if (response.user == null) {
      throw Exception('Failed to update password');
    }
  }

  /// 登出
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 获取当前用户信息
  Future<models.User?> getCurrentUser() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final user =
          await _fetchUserProfileWithRetry(currentUser.id, maxRetries: 2);

      // 如果是买手，检查并分配每日颜色
      if (user.isBuyer) {
        try {
          await _assignDailyColorIfNeeded(user);
        } catch (_) {}
      }

      return user;
    } catch (e) {
      print('getCurrentUser failed: $e');
      return null;
    }
  }

  /// 分配每日颜色（如果需要）
  Future<void> _assignDailyColorIfNeeded(models.User user) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // 如果今天已分配颜色，直接返回
    if (user.colorAssignedDate != null) {
      final assignedDate =
          user.colorAssignedDate!.toIso8601String().split('T')[0];
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
  /// 获取用户每日颜色
  Future<String?> getDailyColor(String userId) async {
    final userDoc = await _supabase
        .from('users')
        .select('daily_color')
        .eq('id', userId)
        .maybeSingle();

    return userDoc?['daily_color'] as String?;
  }

  /// 通过团队名或邀请码 + 密码加入团队
  Future<models.User> joinTeamWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // 服务端 RPC（join_team）验证密码并原子地设置当前用户的 team_id
    final teamService = TeamService(_supabase);
    await teamService.joinTeamByIdentifierAndPassword(
      identifier: identifier,
      password: password,
    );

    // 返回更新后的用户信息
    final userDoc = await _supabase
        .from('users')
        .select()
        .eq('id', currentUser.id)
        .single();

    return models.User.fromJson(userDoc);
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
