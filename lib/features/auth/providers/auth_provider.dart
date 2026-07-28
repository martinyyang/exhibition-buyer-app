import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;
import '../../../core/services/supabase_client.dart';

// Supabase客户端Provider
// 注意：这是整个应用中唯一应该直接使用 Supabase.instance 的地方
// 其他所有地方都应该通过这个 provider 来获取
final supabaseServiceProvider = Provider((ref) {
  return SupabaseService(Supabase.instance.client);
});

// AuthService Provider
final authServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AuthService(supabase.client);
});

// 当前用户Provider (AuthState)
final currentUserProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// 当前用户完整信息Provider (包含teamId等)
final currentUserDataProvider = FutureProvider<app_user.User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

// 用户每日颜色Provider
final userDailyColorProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUserId;

  if (userId == null) return null;

  return await authService.getDailyColor(userId);
});
