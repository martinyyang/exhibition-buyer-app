import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../../../core/services/supabase_client.dart';

// Supabase客户端Provider
final supabaseServiceProvider = Provider((ref) {
  return SupabaseService(supabaseClient);
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
final currentUserDataProvider = FutureProvider<User?>((ref) async {
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
