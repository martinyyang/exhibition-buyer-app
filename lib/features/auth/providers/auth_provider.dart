import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
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

// 当前用户Provider
final currentUserProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// 用户每日颜色Provider
final userDailyColorProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUserId;

  if (userId == null) return null;

  return await authService.getDailyColor(userId);
});
